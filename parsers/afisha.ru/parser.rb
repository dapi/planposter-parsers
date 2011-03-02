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
require 'date'
#require 'action_view'

#include ActionView::Helpers::SanitizeHelper

@parser = ParseUtils.new(false) # debug отключен

@USERAGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.9.0.4) Gecko/2008102920 AdCentriaIM/1.7 Firefox/3.0.4"
@to_utf8 = Iconv.new("utf-8", "windows-1251")
@host_url = "http://www.afisha.ru"

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

@categories = {
  'cinema'  => 'Кино',
  'concert' => 'Концерты',
  'theatre' => 'Театр',
  'club'    => 'Клубы'
}

######################################################################
######################################################################

@events_yml_path = File.expand_path(File.dirname(__FILE__) + "/events.yml")
begin
  @events = YAML.load_file(@events_yml_path)
rescue
  @events = {}
end

def find_details_in_garbage str
  temp = str.split('<br>')
  #temp.map { |t| strip_tags(t).gsub(/[\s]+/m, ' ').strip }
  temp.map { |t| Nokogiri::HTML(t).text.gsub(/[\s]+/m, ' ').strip }
end

def get_event_from_site( category, event_id )
  event_url = [@host_url, category, "#{event_id}\/"].join('/')
  #puts event_url
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(event_url) )
  end
  return nil if not doc
  doc = doc.xpath("//div[@id='container']//div[@id='content']").first
  event_dump = doc.to_s
  event_name = doc.xpath(".//div[@class='b-object-summary']/div[1]/h1").text.gsub(/[\s]+/m, ' ').strip
  return nil if event_name.empty?
  #puts event_name
  raw_details = find_details_in_garbage( doc.xpath(".//div[@class='b-object-summary']/div[2]").to_s )
  raw_details = raw_details.values_at(1...raw_details.length)
  details = []
  period = nil
  raw_details.each do |str|
    next if not str.scan(@regex_monthes).empty?
    find_period = str.scan(/[\d]+(?=\s*?мин.)/).pop
    if find_period
      period = find_period.gsub(/[^\d]/, '').to_i
      str = str.gsub(/,\s*?[\d]+\s*?мин./, '')
    end
    details += [str]
  end
  details = details.join("\n").strip
  #puts details, period
  image_url = doc.xpath(".//div[contains(@class,'b-object-img')]/img").first
  image_url = image_url['src'] if image_url
  event = {}
  event['subject'] = event_name
  event['details'] = details if not details.empty?
  event['period'] = period if period
  event['image_url'] = image_url if image_url
  event['url'] = event_url
  event['dump'] = event_dump
  event
end
#get_event_from_site('concert', 668124)
#get_event_from_site('movie', 202215)
#get_event_from_site('movie', 202657)
#get_event_from_site('concert', 668124)
#get_event_from_site('concert', 669048)
#puts get_event_from_site('performance', 64933).to_json
#puts get_event_from_site('performance', 64673).to_json
#puts get_event_from_site('concert', 665150).to_json

def get_event( event_category, event_id )
  event = get_deep_value( @events, event_category, event_id )
  if not event
    event = get_event_from_site( event_category, event_id )
    return nil if not event
    set_deep_value( @events, event, event_category, event_id )
  end
  event
end

######################################################################
######################################################################

@places_yml_path = File.expand_path(File.dirname(__FILE__) + "/places.yml")
begin
  @places = YAML.load_file(@places_yml_path)
rescue
  @places = {}
end

def find_address_in_garbage str
  #temp = str.scan(/>[^<>]+</m)
  #temp.map! { |x| x.gsub(/[<>\s]+/m, ' ').strip }
  #temp.find { |x| (not x.scan(/[\d]/).empty?) and (x.length > 8) }
  temp = str.split('<br>')
  temp.map! { |t| Nokogiri::HTML(t).text.gsub(/[\s]+/m, ' ').strip }
  temp.shift
  temp.find { |x| (x.scan(/\d/).length >= 3) and (x.length > 8) }
end

def get_place_from_site( city, category, place_id )
  place = {}
  place_url = [@host_url, city, category, "#{place_id}\/"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(place_url) )
  end
  return nil if not doc
  doc = doc.xpath("//div[@id='container']//div[@id='content']//div[@class='b-object-summary']").first
  place_dump = doc.to_s
  place_name = doc.xpath("./div[1]/h1").text.gsub(/[\s]+/m, ' ').strip
  address = find_address_in_garbage( doc.xpath("./p[1]").to_s )
  {
    'name'     => place_name,
    'address'  => address,
    'city'     => city,
    'category' => category,
    'url'      => place_url,
    'dump'     => place_dump
  }
end
#puts get_place_from_site( 'msk', 'theatre', 15877838 )['address']
#puts get_place_from_site( 'ekaterinburg', 'club', 11943 )['address']
#puts get_place_from_site( 'ekaterinburg', 'cinema', 2975 )['address']
#puts get_place_from_site( 'msk', 'sportbuilding', 9445 )['address']
#puts get_place_from_site( 'msk', 'cinema', 3077 )['address']

def get_place( city, category, place_id )
  place = get_deep_value( @places, city, category, place_id )
  if not place
    place = get_place_from_site( city, category, place_id )
    return nil if not place
    set_deep_value( @places, place, city, category, place_id )
  end
  place
end

######################################################################
######################################################################

# for cinema
def get_schedule_type_1( city, category, url_postfix )
  events = [] # {event_id, event_url, place_id, place_url, date, time}
  if url_postfix.empty?
    schedule_url = [@host_url, city, "schedule_#{category}/"].join('/')
    date = Date.today
  else
    schedule_url = [@host_url, city, "schedule_#{category}", "#{url_postfix}\/"].join('/')
    date = Date.parse(url_postfix)
  end
  #puts schedule_url
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(schedule_url) )
  end
  return [] if not doc
  event_divs = doc.xpath("//div[@id='container']//div[@id='schedule']/div")
  event_divs.each do |div|
    schedule_dump = div.to_s
    event_id = div.xpath(".//h3[1]/a[1]").first
    #puts event_id
    event_category = event_id['href'].split('/')[-2]
    event_id = event_id['href'].split('/')[-1].to_i
    place_trs = div.xpath("./table[1]/tbody/tr")
    #puts place_trs.length
    place_city     = nil
    place_category = nil
    place_id       = nil
    place_trs.each do |tr|
      place          = tr.xpath("./td[1]/a[1]").first
      #puts place.to_s
      place_city     = place ? place['href'].split('/')[-3] : place_city
      place_category = place ? place['href'].split('/')[-2] : place_category
      place_id       = place ? place['href'].split('/')[-1].to_i : place_id
      time_spans     = tr.xpath("./td[2]/div[@class='line']/span")
      time_spans.each do |span|
        next if span.text.scan(/\d/).empty?
        time = span.text.gsub(/[^\d:]/, '')
        event = {
          'id'             => event_id,
          'category'       => event_category,
          'place_id'       => place_id,
          'place_city'     => place_city,
          'place_category' => place_category,
          'date'           => date,
          'time'           => time,
          'url'            => schedule_url,
          'dump'           => schedule_dump
        }
        #puts event.to_json
        events.push( event )
      end
    end
  end
  events
end
#puts get_schedule_type_1( 'ekaterinburg', 'cinema', '05-03-2011' ).to_json
#get_schedule_type_1( 'msk', 'cinema', '' )

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
def get_schedule_type_2( city, category, url_postfix )
  events = [] # {event_id, event_url, place_id, place_url, date, time}
  schedule_url = [@host_url, city, "schedule_#{category}", "#{url_postfix}\/"].join('/')
  #puts schedule_url
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(schedule_url) )
  end
  return [] if not doc
  event_trs = doc.xpath("//div[@id='container']//div[@id='schedule']/table[1]/tr")
  event_trs.each do |tr|
    schedule_dump = tr.to_s
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
      'time'           => time,
      'url'            => schedule_url,
      'dump'           => schedule_dump
    }
    #puts event.to_json
    events.push( event )
  end
  events
end
#puts get_schedule_type_2( 'ekaterinburg', 'concert', '28-02-2011/reset' ).to_json

# for theatre
def get_schedule_type_3( city, category, url_postfix )
  events = [] # {event_id, event_url, place_id, place_url, date, time}
  schedule_url = [@host_url, city, "schedule_#{category}", "#{url_postfix}\/"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(schedule_url) )
  end
  return [] if not doc
  place_divs = doc.xpath("//div[@id='container']//div[@id='schedule']/div")
  place_divs.each do |div|
    schedule_dump = div.to_s
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
        'time'           => time,
        'url'            => schedule_url,
        'dump'           => schedule_dump
      }
      #puts event.to_json
      events.push( event )
    end
  end
  events
end
#puts get_schedule_type_3( 'ekaterinburg', 'theatre', '7-03-2011/reset' ).to_json

def get_schedule( city, category, url_postfix )
  case category
  when 'cinema'
    get_schedule_type_1( city, category, url_postfix )
  when 'concert', 'club'
    get_schedule_type_2( city, category, url_postfix )
  when 'theatre'
    get_schedule_type_3( city, category, url_postfix )
  end
end
#puts get_schedule( 'ekaterinburg', 'cinema', '04-03-2011' ).to_json

######################################################################
######################################################################

def get_schedule_url_postfixes( city, category )
  dates = []
  schedule_dates_url = [@host_url, city, "schedule_#{category}\/"].join('/')
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(schedule_dates_url) )
  end
  return [] if not doc
  a_dates = doc.xpath("//div[@id='content']//div[@class='m-schedule-top-mrg'][1]//select[contains(@id, 'DateNavigator')][1]/option")
  a_dates.each do |a_date|
    dates.push( a_date['value'] )
  end
  dates
end
#puts get_schedule_url_postfixes( 'ekaterinburg', 'cinema' ).to_json
#puts get_schedule_url_postfixes( 'msk', 'theatre' ).to_json
#puts get_schedule_url_postfixes( 'msk', 'club' ).to_json
#puts get_schedule_url_postfixes( 'msk', 'concert' ).to_json

######################################################################
######################################################################

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

######################################################################
######################################################################

def main
  cities = get_cities
  #cities = { 'msk' => 'Москва' }
  cities.keys.each do |city|
    @categories.keys.each do |category|
      url_postfixes = get_schedule_url_postfixes( city, category )
      url_postfixes.each do |url_postfix|
        #puts city, category, url_postfix
        events = get_schedule( city, category, url_postfix )
        events.each do |event_iter|
          event = get_event( event_iter['category'], event_iter['id'] )
          event = Marshal.load( Marshal.dump(event) )
          next if not event
          place = get_place(
            event_iter['place_city'],
            event_iter['place_category'],
            event_iter['place_id']
          )
          next if not place
          event['source']    = @host_url
          event['url']       = [
            event_iter['url'],
            place['url'],
            event['url']
          ]
          event['category']  = @categories[category]
          event['place']     = place['name']
          event['address']   = place['address']
          event['city']      = cities[city]
          event['date']      = event_iter['date']
          event['time']      = event_iter['time']
          event['dump_type'] = 'text'
          event['dump']      = [
            event_iter['dump'],
            place['dump'],
            event['dump']
          ]
          #puts event.to_json
          @parser.save_event event
        end
      end
    end
  end
  events_yml = File.open(@events_yml_path, 'w')
  events_yml.write( @events.to_yaml )
  events_yml.close()
  places_yml = File.open(@places_yml_path, 'w')
  places_yml.write( @places.to_yaml )
  places_yml.close()
end

main
