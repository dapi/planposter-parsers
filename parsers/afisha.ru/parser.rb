#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'nokogiri'
require 'open-uri'
require 'json'
require 'curb'
require 'iconv'
#require 'jcode'
require 'date'

@USERAGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.9.0.4) Gecko/2008102920 AdCentriaIM/1.7 Firefox/3.0.4"
@to_utf8 = Iconv.new("utf-8", "windows-1251")
@host_url = "http://www.afisha.ru"

def easy_curl url
  doc = Curl::Easy.perform(url) do |curl|
    curl.headers["User-Agent"] = @USERAGENT
    curl.headers["Reffer"] = @host_url
    curl.enable_cookies = true
    curl.cookiefile = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
    curl.cookiejar = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
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



@events_yml_path = File.expand_path(File.dirname(__FILE__) + "/events.yml")
begin
  @events = YAML.load_file(@events_yml_path)
rescue
  @events = {}
end

def get_event_from_site( event_category, event_id )
  
end

def get_event( event_category, event_id )
  event = get_deep_value( @events, event_category, event_id )
  if not event
    event = get_event_from_site( event_category, event_id )
    return nil if not event
    set_deep_value( @events, event, event_category, event_id )
  end
  event
end



@places_yml_path = File.expand_path(File.dirname(__FILE__) + "/places.yml")
begin
  @places = YAML.load_file(@places_yml_path)
rescue
  @places = {}
end

def get_place_from_site( city, category, place_id )
  place = {}
  place_url = [@host_url, city, category, "#{place_id}\/"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(place_url) )
  end
  return [] if not doc
  doc = doc.xpath("//div[@id='container']//div[@id='content']//div[@class='b-object-summary']").first
  place_name = doc.xpath("./div[1]/h1").text.gsub(/[\s]+/, ' ').strip
  #puts doc.xpath("./p[1]").to_s.gsub(/<a.+<\/a>/m, ' ').gsub(/<span.+<\/span>/m, ' ')
  puts doc.xpath("./p[1]").to_s.gsub(/(<[^>]*>)|\n|\t/s, ' ')
  puts doc.xpath("./p[1]").text
  addresses = doc.xpath("./p[1]").to_s.gsub(/<a.+?<\/a>/m, ' ').scan(/<\/span>.+?<br>/m)
  addresses.shift
  #puts addresses.to_json
  address = nil
  addresses.each do |a|
    #puts a
    address = a.gsub(/([\s]+)|(<\/span>)|(<br>)/m, ' ').strip
    break if address.length > 7
  end
  {
    'name'     => place_name,
    'address'  => address,
    'city'     => city,
    'category' => category
  }
end
get_place_from_site( 'msk', 'theatre', 15877838 ).to_json
#get_place_from_site( 'ekaterinburg', 'club', 11943 ).to_json

def get_place( city, category, place_id )
  place = get_deep_value( @places, city, category, place_id )
  if not place
    place = get_place_from_site( city, category, place_id )
    return nil if not place
    set_deep_value( @places, place, city, category, place_id )
  end
  place
end



def get_schedule( city, category, url_postfix )
  case category
  when 'cinema'
    get_shedule_type_1( city, category, url_postfix )
  when ['concert', 'club']
    get_shedule_type_2( city, category, url_postfix )
  when 'theatre'
    get_shedule_type_3( city, category, url_postfix )
  end
end

# for cinema
def get_shedule_type_1( city, category, url_postfix )
  events = [] # {event_id, event_url, place_id, place_url, date, time}
  schedule_url = [@host_url, city, "schedule_#{category}", "#{url_postfix}\/"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(schedule_url) )
  end
  return [] if not doc
  event_divs = doc.xpath("//div[@id='container']//div[@id='schedule']/div")
  event_divs.each do |div|
    event_id = div.xpath(".//h3[1]/a[1]").first
    #puts event_id
    event_category = event_id['href'].split('/')[-2]
    event_id = event_id['href'].split('/')[-1].to_i
    place_trs = div.xpath("./table[1]/tbody/tr")
    place_trs.each do |place|
      place_id = place.xpath("./td[1]/a[1]").first
      #puts place_id
      place_city = place_id['href'].split('/')[-3]
      place_category = place_id['href'].split('/')[-2]
      place_id = place_id['href'].split('/')[-1].to_i
      time_spans = place.xpath("./td[2]/div/span")
      time_spans.each do |time|
        event = {
          'id'             => event_id,
          'category'       => event_category,
          'place_id'       => place_id,
          'place_city'     => place_city,
          'place_category' => place_category,
          'date'           => url_postfix,
          'time'           => time.text.gsub(/[^\d:]/, '')
        }
        #puts event.to_json
        events.push( event )
      end
    end
  end
  events
end
#puts get_shedule_type_1( 'ekaterinburg', 'cinema', '04-03-2011' ).to_json

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

def date_parse raw_day, raw_month
  str_month = raw_month.scan(@regex_monthes)[0]
  month = @monthes[str_month]
  return if not month
  day = raw_day.to_i
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

# for concert and club
def get_shedule_type_2( city, category, url_postfix )
  events = [] # {event_id, event_url, place_id, place_url, date, time}
  schedule_url = [@host_url, city, "schedule_#{category}", "#{url_postfix}\/"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(schedule_url) )
  end
  return [] if not doc
  event_trs = doc.xpath("//div[@id='container']//div[@id='schedule']/table[1]/tr")
  event_trs.each do |tr|
    event = tr.xpath(".//h3[1]/a[1]").first
    #puts event_id
    event_category = event['href'].split('/')[-2]
    event_id = event['href'].split('/')[-1].to_i
    place = tr.xpath("./td[1]/p[1]/a[1]").first
    #puts place
    place_city = place['href'].split('/')[-3]
    place_category = place['href'].split('/')[-2]
    place_id = place['href'].split('/')[-1].to_i
    datetime = tr.xpath("./td[2]").text.gsub(/[\s]+/, ' ')
    datetime = datetime.scan(/(\d+)\s*(.+?)\s*,\s*(\d+:\d+)/).pop
    #puts datetime.to_json
    next if not datetime
    time = datetime[2]
    date = date_parse(datetime[0], datetime[1])
    next if not date
    event = {
      'id'             => event_id,
      'category'       => event_category,
      'place_id'       => place_id,
      'place_city'     => place_city,
      'place_category' => place_category,
      'date'           => date,
      'time'           => time
    }
    #puts event.to_json
    events.push( event )
  end
  events
end
#puts get_shedule_type_2( 'ekaterinburg', 'concert', '28-02-2011/reset' ).to_json

# for theatre
def get_shedule_type_3( city, category, url_postfix )
  events = [] # {event_id, event_url, place_id, place_url, date, time}
  schedule_url = [@host_url, city, "schedule_#{category}", "#{url_postfix}\/"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(schedule_url) )
  end
  return [] if not doc
  place_divs = doc.xpath("//div[@id='container']//div[@id='schedule']/div")
  place_divs.each do |div|
    place = div.xpath("./div[1]/h3[1]/a[1]").first
    place_city = place['href'].split('/')[-3]
    place_category = place['href'].split('/')[-2]
    place_id = place['href'].split('/')[-1].to_i
    event_trs = div.xpath("./table[1]/tbody[1]/tr")
    event_trs.each do |tr|
      event = tr.xpath("./td[1]/a[1]").first
      event_id = event['href'].split('/')[-1].to_i
      event_category = event['href'].split('/')[-2]
      datetime = tr.xpath("./td[2]").text.gsub(/[\s]+/, ' ')
      datetime = datetime.scan(/(\d+)\s*(.+?)\s*,\s*(\d+:\d+)/).pop
      next if not datetime
      time = datetime[2]
      date = date_parse(datetime[0], datetime[1])
      next if not date
      event = {
        'id'             => event_id,
        'category'       => event_category,
        'place_id'       => place_id,
        'place_city'     => place_city,
        'place_category' => place_category,
        'date'           => date,
        'time'           => time
      }
      #puts event.to_json
      events.push( event )
    end
  end
  events
end
#puts get_shedule_type_3( 'ekaterinburg', 'theatre', '7-03-2011/reset' ).to_json



def get_schedule_url_postfixes( city, category )
  dates = []
  schedule_dates_url = [@host_url, city, "schedule_#{category}\/"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(schedule_dates_url) )
  end
  return [] if not doc
  a_dates = doc.xpath("//div[@class='m-schedule-top-mrg'][1]/div[contains(@class,'b-panel-filter')][1]/select[1]/option")
  a_dates.each do |a_date|
    dates.push( a_date['value'] )
  end
  dates
end
#puts get_schedule_dates( 'ekaterinburg', 'club' ).to_json



@categories = {
  'cinema'  => 'Кино',
  'concert' => 'Концерты',
  'theatre' => 'Театр',
  'club'    => 'Клубы'
}



def get_cities
  cities = {}
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(@host_url) )
  end
  return [] if not doc
  a_cities = doc.css("ul[class='s-dropdown afh-dd-city'] li a")
  a_cities.each do |city|
    city_name = city.text
    city_code = city['href'].scan(/\w+(?=\/changecity)/).pop
    next if not city_code
    cities[city_code] = city_name
  end
  cities
end
#puts get_cities.to_json



def main
end
