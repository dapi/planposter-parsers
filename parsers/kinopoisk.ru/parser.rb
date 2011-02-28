#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$: << File.expand_path(File.dirname(__FILE__) + '/../..')
require 'lib/parseutils'

require 'nokogiri'
require 'open-uri'
require 'json'
require 'curb'
require 'iconv'
#require 'jcode'

@parser = ParseUtils.new(false) # debug отключен

@USERAGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.9.0.4) Gecko/2008102920 AdCentriaIM/1.7 Firefox/3.0.4"
@to_utf8 = Iconv.new("utf-8", "windows-1251")
@host_url = "http://www.kinopoisk.ru"

@cinemas_yml_path = File.expand_path(File.dirname(__FILE__) + "/cinemas.yml")
begin
  @cinemas = YAML.load_file(@cinemas_yml_path)
rescue
  @cinemas = {}
end

@movies_yml_path = File.expand_path(File.dirname(__FILE__) + "/movies.yml")
begin
  @movies = YAML.load_file(@movies_yml_path)
rescue
  @movies = {}
end

@monthes = {
  'января' => 1,
  'февраля' => 2,
  'марта' => 3,
  'апреля' => 4,
  'мая' => 5,
  'июня' => 6,
  'июля' => 7,
  'августа' => 8,
  'сентября' => 9,
  'октября' => 10,
  'ноября' => 11,
  'декабря' => 12
}

@regex_monthes = /января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря/

def date_parse str
  str_month = str.scan(@regex_monthes)[0]
  month = @monthes[str_month]
  return if not month
  day = str.scan(/\d+/)[0].to_i
  return if day==0
  today = Date.today
  if day < today.day and month == 12
    year = today.year + 1
  else
    year = today.year
  end
  #puts year, year.class, month, month.class, day, day.class
  return "#{year}-#{"%02d"%month}-#{"%02d"%day}"
end

def easy_curl url
  doc = Curl::Easy.perform(url) do |curl|
    curl.headers["User-Agent"] = @USERAGENT
    curl.headers["Reffer"] = "http://www.kinopoisk.ru"
  end
  return doc.body_str
end

def retry_if_exception(&block)
  attempt = 10
  begin
    return yield
  rescue OpenURI::HTTPError => e
    code = e.to_s.split()[0].to_i
    attempt -= 1
    retry if attempt > 0 and code == 500
  end
end

def get_cities
  cities = {}
  url = [@host_url, 'level/9'].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return {} if not doc
  opt_cities = doc.xpath("//select[@id='id_city']/option")
  opt_cities.each do |city|
    cities[ city['value'].to_i ] = city.text.strip
  end
  cities
end

def get_city_cinemas(city_id)
  cinemas = @cinemas[city_id]
  if not cinemas
    cinemas = get_city_cinemas_from_site(city_id)
    return {} if not cinemas
    @cinemas[city_id] = cinemas if not cinemas.empty?
  end
  cinemas
end

# пример ссылки:
# http://www.kinopoisk.ru/level/9/tc/[код города]/perpage/[количество кинотеатров на странице]/page/[номер страницы]/
# http://www.kinopoisk.ru/level/9/tc/1/perpage/10/page/2/
def get_city_cinemas_from_site(city_id)
  cinemas = {}
  city_url = [@host_url, 'level/9/tc', city_id, 'perpage/200/page/1'].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(city_url) )
  end
  return if not doc
  doc = doc.xpath("//div[@id='content_block']")
  begin
    pages = doc.xpath(".//div[@class='navigator'][1]//li[@class='arr'][last()]//a")
    pages = pages.first()['href'].split('/')[-1].to_i
  rescue
    pages = 1
  end
  pages.times do |x|
    page = x+1
    city_url = [@host_url, 'level/9/tc', city_id, 'perpage/200/page', page].join('/')
    if page > 1
      doc = nil
      retry_if_exception do
        doc = Nokogiri::HTML( easy_curl(city_url) )
      end
      next if not doc
    end
    doc = doc.xpath("//div[@class='block_left']")
    tr_cinemas = doc.xpath(".//tr[contains(@class,'cinema_')][position() mod 2 != 0]")
    tr_cinemas.each do |x|
      cinema                  = {}
      cinema['cinema_dump']   = x.to_s
      cinema['id']            = x['class'].split('_')[-1].to_i
      next if cinemas.include?(cinema['id'])
      cinema['city_id']       = city_id
      cinema['name']          = x.xpath('.//a').first().text().strip
      address = x.xpath('.//td').last().children().to_s.split("<br>")[0].strip
      cinema['address']       = @to_utf8.iconv( address )
      cinema['cinema_url']    = [@host_url, 'level/8/cinema', cinema['id']].join('/')
      cinema['city_url']      = city_url
      cinemas[ cinema['id'] ] = cinema
    end
  end
  cinemas
end

# пример ссылки:
# http://www.kinopoisk.ru/level/8/cinema/[код кинотеатра]/
# http://www.kinopoisk.ru/level/8/cinema/263348/
def get_cinema_movies(cinema_id)
  movies = []
  cinema_url = [@host_url, 'level/8/cinema', cinema_id].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(cinema_url) )
  end
  return [] if not doc
  dates = doc.xpath("//div[@class='block_left']/table[last()]/tr[1]/td/table[position()>=3 and position()<=last()-1]")
  dates.each do |date|
    date_dump = date.to_s
    event_date = date.xpath("./tr").first.text.split(',')[-1].strip
    tr_movies = date.xpath(".//tr[@class='cinema_row']")
    tr_movies.each do |mov|
      movie_id = mov.xpath(".//a[1]").first()['href'].split('/')[-1].to_i
      times = mov.xpath(".//b[contains(@class,'time_')]").map { |x| x.text.gsub(/[^\d:]+/, '') }
      times.each do |time|
        movie              = {}
        movie['movie_id']  = movie_id
        movie['date']      = event_date
        movie['time']      = time
        movie['date_dump'] = date_dump
        movies.push( movie )
      end
    end
  end
  movies
end

def get_movie(movie_id)
  movie = @movies[movie_id]
  if not movie
    movie = get_movie_from_site(movie_id)
    return if not movie
    @movies[movie_id] = movie
  end
  movie
end

# http://www.kinopoisk.ru/level/1/film/474714/
def get_movie_from_site(movie_id)
  movie = {}
  movie['movie_url'] = [@host_url, 'level/1/film', movie_id].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(movie['movie_url']) )
  end
  return if not doc
  doc = doc.xpath("//div[@class='movie'][1]/table/tr[2]/td[1]/table")
  movie['name'] = doc.xpath("./tr[1]//*[@class='moviename-big'][1]").text.strip
  return if movie['name'].empty?
  movie['movie_dump'] = doc.xpath("//div[@class='movie'][1]").first.to_s
  doc = doc.xpath("./tr[2]")
  begin
    movie['image_url'] = doc.xpath("./td[1]//a[1]//img[1]").first['src']
  rescue
  end
  tr_details = doc.xpath(".//table[@class='info']/tr")
  details = []
  tr_details.each do |detail|
    if detail.xpath("./td[2][@class='time']").first
      movie['period'] = detail.xpath("./td[2][@class='time']").text.scan(/\d+/)[0].to_i
      next
    end
    detail_type = detail.xpath("./td[1]").text.gsub(/[\s]+/, ' ').strip
    next if detail_type.empty?
    detail_value = detail.xpath("./td[2]").text.gsub(/[\s]+/, ' ').strip
    next if detail_value.empty?
    details += ["#{detail_type}: #{detail_value}"]
  end
  if not details.empty?
    details = details.join("\n")
    movie['details'] = details
  end
  movie
end

#puts get_movie(474714).to_json
#puts get_movie(471158).to_json
#puts get_cinema_movies(263348).to_json
#puts get_cinema_movies(264301).to_json
#puts get_city_cinemas(1).to_json
#puts get_city_cinemas(2).to_json

def main
  cities = get_cities
  #cities = { 1 => 'Москва' }
  cities.keys.each do |city_id|
    cinemas = get_city_cinemas(city_id)
    cinemas.keys.each do |cinema_id|
      movies = get_cinema_movies(cinema_id)
      movies.each do |mov|
        movie = get_movie(mov['movie_id'])
        next if not movie
        event             = {}
        event['source']    = @host_url
        event['url']       = [
          movie['movie_url'],
          cinemas[cinema_id]['cinema_url'],
          cinemas[cinema_id]['city_url']
        ]
        #event['uid']       = mov['movie_id']
        event['subject']   = movie['name']
        event['details']   = movie['details'] if movie['details']
        event['image_url'] = movie['image_url'] if movie['image_url']
        event['category']  = 'Кино'
        event['place']     = cinemas[cinema_id]['name']
        event['address']   = cinemas[cinema_id]['address']
        event['city']      = cities[city_id]
        event['date']      = date_parse( mov['date'] )
        next if not event['date']
        event['time']      = mov['time']
        event['period']    = movie['period'] if movie['period']
        event['dump_type'] = 'text'
        event['dump']      = [
          movie['movie_dump'],
          mov['date_dump'],
          cinemas[cinema_id]['cinema_dump']
        ]
        #puts event.to_json
        @parser.save_event event
      end
    end
  end
  cinemas_yml = File.open(@cinemas_yml_path, 'w')
  cinemas_yml.write( @cinemas.to_yaml )
  cinemas_yml.close()
  movies_yml = File.open(@movies_yml_path, 'w')
  movies_yml.write( @movies.to_yaml )
  movies_yml.close()
end

main()
