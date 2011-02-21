#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'

timeout_schedules = [
  'http://www.timeout.ru/books/schedule/',
  'http://www.timeout.ru/childs/schedule/',
  'http://www.timeout.ru/theatre/schedule/',
  'http://www.timeout.ru/exhibition/schedule/',
  'http://www.timeout.ru/music/schedule/',
  'http://www.timeout.ru/clubs/schedule/',
  'http://www.timeout.ru/cinema/schedule/',
  'http://www.timeout.ru/city/schedule/'
]

def puts_event (event)
  puts <<-EOS
  ===============================================================
  {
    source:   '#{event['source']}',
    page:     '#{event['page']}',
    subject:  '#{event['subject']}',
    place:    '#{event['place']}',
    category: '#{event['category']}',
    address:  '#{event['addres']}',
    date:     '#{event['date']}',
    time:     '#{event['time']}',
    period:   '#{event['period']}',
    details:  '#{event['details']}',
    dump:     '#{event['dump']}'
  }
  =================================================================
  EOS
end

def child_parse
  doc = Nokogiri::HTML(open("http://www.timeout.ru/childs/schedule/"))
  categories = doc.xpath("//div[@class='w-list teatry']//div[@class='b-genre']")
  categories.each do |category|
    category_name = category.xpath("strong").children[1]
    #puts child_category_name
    category_types = category.css("div.w-list-block")
    #puts child_category_events[0]['class']
    category_types.each do |category_type|
      type_name = category_type['class'].split()[1]
      case type_name
      when 'vistavki'
        events = category_type.css('div.w-row')
        events.each do |event|
          event_title = event.xpath("a[@class='w-event']").text
          place_name = event.xpath("a[@class='w-place']").text
          puts_event 'subject'=>event_title, 'place'=>place_name
        end
      when 'teatr'
        event_title = category_type.xpath("h3//a").text
        event_places = category_type.css('div.w-row')
        event_places.each do |place|
          place_name = place.xpath("a").text
          times = place.xpath("span").text
          times = times.gsub(/[^0-9:]/, ' ').split
          times.each do |time|
            puts_event 'subject'=>event_title, 'place'=>place_name, 'time'=>time
          end
        end
      end
    end
  end
end

child_parse
