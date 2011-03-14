#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$: << File.expand_path(File.dirname(__FILE__) + '/../..')
require 'lib/parseutils'

require 'nokogiri'
require 'open-uri'
require 'json'
require 'curb'
#require 'jcode'
require 'date'
require 'html2text'
require 'chronic'

@parser = ParseUtils.new(false) # debug отключен

@USERAGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/534.21 (KHTML, like Gecko) Chrome/11.0.678.0 Safari/534.21"
@host_url = "http://eventful.com"

def easy_curl url
  doc = Curl::Easy.perform(url) do |curl|
    curl.headers["User-Agent"] = @USERAGENT
    curl.headers["Reffer"] = @host_url
    curl.enable_cookies = true
    curl.cookiefile = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
    curl.cookiejar = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
    curl.timeout = 30
    curl.follow_location = true
    curl.max_redirects = 5
  end
  return doc.body_str
end

def retry_if_exception(&block)
  attempt = 10
  begin
    return yield
  #rescue OpenURI::HTTPError => e
  #  code = e.to_s.split()[0].to_i
  #  attempt -= 1
  #  retry if attempt > 0 and code == 500
  rescue Exception => e
    #puts e
    attempt -= 1
    retry if attempt > 0
  end
end

def get_deep_value(hash, *keys)
  keys.each do |key|
    return nil if hash.class != Hash
    hash = hash[key]
  end
  hash
end

def set_deep_value(hash, value, *keys)
  last_key = keys.pop
  keys.each do |key|
    return false if hash.class != Hash 
    hash[key] = {} if not hash[key]
    hash = hash[key]
  end
  return false if hash.class != Hash 
  hash[last_key] = value
end

######################################################################
######################################################################

def get_categories
  url = [@host_url, "events"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return [] if not doc
  doc = doc.xpath("//div[@id='quick-search-cat']").first
  return [] if not doc
  
  result = []
  
  categories = doc.xpath("./div[2]/ul[1]//a")
  categories.each do |c|
    result.push(:name => c.text, :url => c['href'])
  end
  
  special = doc.xpath("./div[2]/ul[3]//a")
  special.each do |c|
    result.push(:name => c.text, :url => c['href'])
  end
  
  result
end

#puts get_categories.to_json

######################################################################
######################################################################

def get_category_page_count category_url
  url = [@host_url, category_url].join()
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return 0 if not doc
  doc = doc.xpath("//div[@id='box-browse-events']//p[@class='pages']//a[@class='end']").first
  return 0 if not doc
  doc.text.strip.to_i
end

#puts get_category_page_count('/events/categories/music')

######################################################################
######################################################################

def get_categoriy_events category_url, page
  url = @host_url + "#{category_url}?page_number=#{page}"
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return [] if not doc
  doc = doc.xpath("//div[@id='box-browse-events']//table[contains(@class,'event-results')]/tr[@class='vevent']")
  events = []
  doc.each do |e|
    next if not e.text.scan(/\d:\d\d/).shift
    events.push( e.xpath("./td[@class='photo']/a").first['href'] )
  end
  events
end

#puts get_categoriy_events('/events/categories/music', 1).to_json
#puts get_categoriy_events('/events/categories/singles_social', 6)
#puts get_categoriy_events('/events/categories', 758)

######################################################################
######################################################################

def get_period start_time, end_time
  #puts start_time, end_time
  period = end_time - start_time
  if period > 0
    (period.round)/60
  else
    (period.round)/60 + 1440
  end
end

def datetime_parse str
  datetime = {}
  str = str.split('|').shift
  #puts str.to_json
  date_str = str.scan(/\w+\s+\w+,\s+\w+\s+/i).shift
  datetime['date'] = Chronic.parse(date_str)
  return {} if not datetime['date']
  datetime['date'] = datetime['date'].strftime("%Y-%m-%d").strip
  times = str.gsub(date_str, '').split('-')
  #puts times.to_json
  start_time = Chronic.parse(times.shift)
  return {} if not start_time
  datetime['time'] = start_time.strftime("%H:%M").strip
  end_time = Chronic.parse(times.shift)
  return datetime if not end_time
  datetime['period'] = get_period(start_time, end_time)
  datetime
end

def get_event event_url
  event = {}
  event['source'] = @host_url
  event['url'] = [event_url]
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(event_url) )
  end
  return if not doc
  event['dump'] = doc.xpath("//div[@class='alpha vevent']").to_s
  event['dump_type'] = 'text'
  #
  ## first part
  div = doc.xpath("//div[@id='box-primary-info']").first
  return if not div
  event['subject'] = div.xpath(".//h1[@id='event-title'][1]").text.strip
  datetime = datetime_parse( div.xpath(".//h2[@id='event-info-start-date'][1]").text.strip )
  return if not ( datetime['date'] and datetime['time'] )
  #puts datetime.to_json
  event['date'] = datetime['date']
  event['time'] = datetime['time']
  event['period'] = datetime['period'] if datetime['period']
  div = div.xpath(".//div[@id='event-info']").first
  image_url = div.xpath("./div[@class='alpha']//img[@id='image-viewer-image'][1]").first
  event['image_url'] = image_url['src'] if image_url
  div = div.xpath("./div[@class='beta']").first
  event['place'] = div.xpath(".//div[@id='event-info-where']/h2[1]").text.gsub(/[\s]+/, ' ').strip
  div.xpath(".//div[@id='event-info-where']/div[@class='adr']/span").each do |s|
    key = s['id'].gsub('event-venue-','')
    key = 'city' if key == 'locality'
    event[key] = s.text.gsub(/[\s]+/, ' ').strip
  end
  return if not (event['address'] and event['city'])
  event['country'] = 'USA' if not event['country']
  #
  ## second part
  div = doc.xpath(".//div[@id='box-details']").first
  return if not div
  div = div.xpath(".//div[@id='event-details-description']/div[@class='description']").first
  categories = []
  div.xpath(".//div[contains(@class,'categories')]//a").each do |x|
    categories.push({
      :name => x.text,
      :url  => x['href']
    })
  end
  div.xpath(".//div[contains(@class,'categories')]").remove
  parser_instance = SAXParser.new
  parser = Nokogiri::HTML::SAX::Parser.new(parser_instance)
  parser.parse(div.to_s)
  details = parser_instance.text.strip
  #puts details
  event['details'] = details if not details.empty?
  [event, categories]
end

#
#get_event('http://eventful.com/dallas/events/monster-ball-tour-lady-gaga-/E0-001-030861135-2').to_json
#puts get_event('http://eventful.com/springfield_va/events/international-bridal-expo-/E0-001-037325964-6').to_json
#puts get_event('http://eventful.com/events/millionaire-mind-intensive-seminar-toronto-march-1113-2011-/E0-001-036523215-8').to_json
#get_event('http://eventful.com/houston/events/warehouse-live-presents-ap-tour-featuring-black-vei-/E0-001-035833710-9').to_json
#puts get_event('http://eventful.com/vancouver/events/cirque-du-soleil-quidam-/E0-001-035716626-7').to_json
#puts get_event('http://eventful.com/losangeles/events/naco-shortfilm-screening-red-cat-international-/E0-001-027185890-5').to_json
#puts get_event('http://eventful.com/events/ozmpsclub-baton-relay-mazda-bbq-/E0-001-037303697-5').to_json
#puts get_event('http://eventful.com/losangeles/events/escape-fate-/E0-001-035294018-7').to_json

######################################################################
######################################################################

def get_movies_dates
  url = 'http://movies.eventful.com/theaters-showtimes'
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return [] if not doc
  selected = false
  dates = []
  doc.xpath("//select[@id='showtimes-filter-date']/option").each do |opt|
    selected = true if opt['selected']=='selected'
    next if not selected
    dates.push( opt['value'] )
  end
  dates
end

def get_first_date
  url = 'http://movies.eventful.com/theaters-showtimes'
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return [] if not doc
  date = doc.xpath("//select[@id='showtimes-filter-date']/option[@selected='selected']").text
  Date.parse(date)
end

#puts get_showtime_dates

######################################################################
######################################################################

def get_movies_page_count d
  url = "http://movies.eventful.com/theaters-showtimes?date=#{d}"
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return 0 if not doc
  doc = doc.xpath("//div[@id='theater-pagination']//p[@class='pages']//a[@class='end']").first
  return 0 if not doc
  doc.text.strip.to_i
end

#puts get_showtime_page_count "2011-03-11"

######################################################################
######################################################################

def get_movies_events date, page
  url = "http://movies.eventful.com/theaters-showtimes?date=#{date}&page_number=#{page}"
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return [] if not doc
  movies = []
  tags = doc.xpath("//div[@id='movie-showtimes']/*")
  cinema = nil
  tags.each do |tag|
    cinema = tag if ( tag['class'] and (not tag['class'].scan('header').empty?) )
    movies_table = tag if tag.name == 'table'
    if movies_table
      #
      ##
      location = {}
      location['place'] = cinema.xpath('./h2').text.strip
      cinema.xpath('./span[1]/span').each do |span|
        key = span['class'].scan(/address|city|locality|region|postal-code|country/).shift
        next if not key
        key = 'city' if key == 'locality'
        location[key] = span.text.strip
      end
      location['country'] = 'USA' if not location['country']
      next if not ( location['city'] and location['address'] )
      #
      ##
      movies_table.xpath("./tbody/tr").each do |mov|
        #event = Marshal.load( Marshal.dump(location) )
        movie_url = mov.xpath("./td[@class='title']//a").first['href'].gsub(/\/showtimes$/,'')
        next if not movie_url
        times = mov.xpath("./td[contains(@class,'showtimes')]").text.split('|')
        times.each do |time|
          event = Marshal.load( Marshal.dump(location) )
          event['url'] = [movie_url, url]
          event['time'] = time.gsub(/[^\d:]+/, '')
          movies.push(event)
        end
      end
    end
    movies_table = nil
  end
  movies
end

#puts get_movies_events('2011-03-13', 20).to_json

######################################################################
######################################################################

def period_parse period_str
  result = 0
  hours = period_str.scan(/\d+(?=\s+hr)/mi).shift
  result += 60*hours.to_i if hours
  minutes = period_str.scan(/\d+(?=\s+min)/mi).shift
  result += minutes.to_i if minutes
  result
end

def get_movie_from_site movie_url
  event = {}
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(movie_url) )
  end
  return if not doc
  event['dump'] = doc.xpath("//div[@class='alpha']").to_s
  event['dump_type'] = 'text'
  #
  ## first part
  div = doc.xpath("//div[@id='movie-info']").first
  return if not div
  event['subject'] = div.xpath(".//div[@class='data'][1]/h1[@class='item'][1]/span[contains(@class,'title')]").text.strip
  return if event['subject'].empty?
  period = period_parse( div.xpath(".//div[@class='data'][1]/p[1]/span[@class='run-time']").text.strip )
  event['period'] = period if period and period>0
  #
  ## second part
  div = doc.xpath(".//div[@id='tab-details']").first
  return event if not div
  div = div.xpath("./div[@class='section last']").first
  div.xpath("./h2").remove
  div.xpath("./div[@id='cast-scroller']").remove
  parser_instance = SAXParser.new
  parser = Nokogiri::HTML::SAX::Parser.new(parser_instance)
  parser.parse(div.to_s)
  details = parser_instance.text.strip
  #puts details
  event['details'] = details if not details.empty?
  event
end

#@movies_yml_path = File.expand_path(File.dirname(__FILE__) + "/movies.yml")
#begin
#  @movies = YAML.load_file(@movies_yml_path)
#rescue
#  @movies = {}
#end
@movies = {}

def get_movie url
  #url = url.gsub('http://','')
  movie = @movies[url]
  if not movie
    movie = get_movie_from_site(url)
    return if not movie
    @movies[url] = movie
  end
  movie
end

#puts get_movie('http://movies.eventful.com/drive-angry-reald-3d-/M0-001-000011324-2').to_json
#puts get_movie_from_site('http://movies.eventful.com/le-m%C3%A3cano-/M0-001-000018591-1').to_json
#puts get_movie_from_site('http://movies.eventful.com/le-m%C3%A9cano-/M0-001-000018591-1').to_json

######################################################################
######################################################################

def parse_movies
  #dates = get_movies_dates
  now = get_first_date
  dates = []
  15.times { |d| dates.push("%04\d"%now.year+"-%02\d"%now.month+"-%02d"%(now.day+d))  }
  dates.each do |d|
    pages = get_movies_page_count d
    (1..pages).each do |page|
      events = get_movies_events d, page
      events.each do |event|
        movie = get_movie(event['url'][0])
        next if not movie
        movie.keys.each { |k| event[k] = movie[k] }
        event['date'] = d
        event['source'] = @host_url
        event['category'] = 'Movie'
        #puts event.to_json
        @parser.save_event event
      end
    end
  end
end

def parse_categroies
  all_categories = "/events/categories"
  pages = get_category_page_count(all_categories).to_i
  (1..pages).each do |page|
    events = get_categoriy_events(all_categories, page)
    events.each do |e|
      event, categories = get_event(e)
      next if not event
      categories.each do |c|
        event['category'] = c[:name]
        #puts event.to_json
        @parser.save_event event
      end
    end
  end
end

def main
  `#{File.expand_path(File.dirname(__FILE__) + "/get_cookies.rb")}`
  parse_movies
  #movies_yml = File.open(@movies_yml_path, 'w')
  #movies_yml.write( @movies.to_yaml )
  parse_categroies
end

main

