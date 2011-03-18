#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$: << File.expand_path(File.dirname(__FILE__) + '/../..')
require 'lib/parseutils'

require 'nokogiri'
require 'open-uri'
require 'json'
require 'curb'
require 'date'
require 'time'
require 'uri'
require 'cgi'

@parser = ParseUtils.new(false) # debug отключен

@USERAGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/534.21 (KHTML, like Gecko) Chrome/11.0.678.0 Safari/534.21"
@host_url = "http://ticketmaster.com"
@uri = "ticketmaster.com"
@categories = {
  'music'  => 'http://www.ticketmaster.com/section/concerts',
  'sports' => 'http://www.ticketmaster.com/section/sports',
  'arts'   => 'http://www.ticketmaster.com/section/arts_theater',
  'family' => 'http://www.ticketmaster.com/section/family'
}
@parsed_events = {}
@events = {}

def easy_curl url
  doc = Curl::Easy.perform(url) do |curl|
    curl.headers["User-Agent"] = @USERAGENT
    curl.headers["Reffer"] = 'http://' + @uri
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
  rescue Exception => e
    attempt -= 1
    retry if attempt > 0
  end
end

def parse_event eid
  #puts eid
  @parsed_events[eid] = 1
  @events.delete(eid)
  url = "http://www.#{@uri}/json/search/event?aid=#{eid}"
  doc = nil
  retry_if_exception do
    doc = easy_curl(url)
  end
  return if not doc
  events = []
  JSON.parse(doc)['response']['docs'].each do |e|
    e['AttractionId'].each do |new_id|
      @events[new_id] = 1 if not @parsed_events[new_id]
    end
    index = e['AttractionId'].index(eid)
    next if not (index and e['AttractionName'][index])
    e['MajorGenre'].each do |category|
      event = {}
      event['country'] = e['VenueCountry']
      event['region']  = e['VenueState'] if e['VenueState']
      event['city']    = e['VenueCity']
      event['address'] = e['VenueAddress']
      event['place']   = e['VenueName']
      next if not (event['city'] and event['address'] and event['place'])
      datetime = Time.parse e['EventDate'] # UTC
      event['date']    = "#{datetime.year}-#{"%02d"%datetime.month}-#{"%02d"%datetime.day}"
      event['time']    = "#{"%02d"%datetime.hour}:#{"%02d"%datetime.min}"
      event['subject'] = CGI.unescapeHTML e['AttractionName'][index]
      event['url']     = [ "http://www." + @uri + e['AttractionSEOLink'][index] ]
      event['source']  = "http://www." + @uri
      event['category'] = category
      image_url = e['AttractionImage'][index]
      image_url = "" if not image_url
      lang_code = e['LangCode']
      event['image_url'] = "http://media.ticketmaster.com/tm/#{lang_code}" + image_url if not image_url.empty?
      event['dump_type'] = "json"
      event['dump']      = e
      events.push event
    end
  end
  events.each do |e|
    #puts e.to_json
    ######################
    ######################
    @parser.save_event e
    ######################
    ######################
  end
end

def get_subcategory_events(category, subcategory)
  url = "http://www.#{@uri}/json/browse/#{category}?g=#{URI.escape(subcategory)}&select=n90"
  doc = nil
  retry_if_exception do
    doc = easy_curl(url)
  end
  return [] if not doc
  JSON.parse(doc)['response']['docs'].each do |e|
    e['AttractionId'].each do |eid|
      @events[eid] = 1 if eid
    end
  end
end
#get_category_events('sports')

def get_subcategories cat
  url = @categories[cat]
  doc = nil
  retry_if_exception do
    doc = Nokogiri::HTML( easy_curl(url) )
  end
  return [] if not doc
  subcat = []
  doc.xpath("//div[@id='left-nav']/div[@class='container-nav'][2]/a").each do |tag|
    subcat.push tag.text.strip
  end
  subcat
end
#puts get_subcategories 'music'

def parse_country
  @categories.keys.each do |cat|
    puts "scan #{cat}"
    get_subcategories(cat).each do |subcat|
      puts "\tscan #{subcat}"
      get_subcategory_events(cat, subcat)
    end
  end
  #puts @events.size
  while not @events.empty? do
    @events.keys.each do |eid|
      parse_event eid
    end
  end
end

def main
  `#{File.expand_path(File.dirname(__FILE__) + "/get_cookies.rb")}`
  countries = [
    ['ticketmaster.com'],
    ['ticketmaster.com.au'],
    ['ticketmaster.ca'],
    ['ticketmaster.ie'],
    ['ticketmaster.com.mx'],
    ['ticketmaster.co.uk'],
    ['ticketmaster.co.nz']
  ]
  countries.each do |country|
    @uri = country[0]
    @parsed_events = {} # здесь хранятся уже обработанные события
    @events = {} # здесь хранятся события на обработку
    @categories = {
      'music'  => "http://www.#{@uri}/section/concerts",
      'sports' => "http://www.#{@uri}/section/sports",
      'arts'   => "http://www.#{@uri}/section/arts_theater",
      'family' => "http://www.#{@uri}/section/family"
    }
    parse_country
  end
end

main

