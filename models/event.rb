# -*- coding: utf-8 -*-
require 'models/category'
require 'models/city'
require 'models/source'

require 'lib/image_downloader'
require 'uri'

class Event
  include DataMapper::Resource
  include DataMapper::CounterCacheable

  property :id,          Serial
  # property :uid,         String
  property :subject,     String
  property :url,         String
  property :source_id,   Integer
  property :start_time,  Time
  property :finish_time, Time
  property :created_at,  Time
  property :address,     String
  property :category_id, Integer
  property :city_id,     Integer
  property :place,       String
  property :image_url,   String
  property :is_whole_day, Boolean
  property :details,     Text

  belongs_to :category, :counter_cache=>true
  belongs_to :city, :counter_cache=>true
  belongs_to :source, :counter_cache=>true

  def self.parse_time(city, data)
    # TODO Учитывать timezone в соответсвии с городом
    # время в базе хранится в utc
    date = Date.parse data["date"]
    data["time"]=nil if data["time"].blank?
    # Time.zone =
    time = Time.parse(data["time"] || '00:00') || Time.parse('00:00')
    time = Time.utc( date.year, date.month, date.day, time.hour, time.min) - city.time_zone_in_seconds
  end

  def self.create_from_parser(data)
    raise "Не указана категория" if data["category"].blank?
    raise "Не указан источник" if data["source"].blank?
    raise "Не указан город" if data["city"].blank?
    if data["date"].blank?
      print "Не указана дата, пока такие не обрабатываем"
      return
    end

    category = Category.first( :name=>data["category"]) || Category.create(:name=>data["category"])
    # raise "Не найдена категория: #{data['category']} для #{data.inspect}" unless category
    city  = City.first(:name=>data["city"]) || City.create(:name=>data["city"])
    data["source"] = data["source"].gsub('http://','').gsub('/','').gsub('www.','')
    data.each_key do |key|
      data[key].strip! if data[key].is_a? String
    end

    source = Source.first( :url=>data["source"] ) or Source.create( :url=>data["source"] )

    attrs = {
      :source => source,
      :subject => data["subject"],
      :address => data["address"],
      :place => data["place"],
      :details => data["details"],
      :url => data["url"],
      :image_url => data["image_url"],
      :category_id => category.id,
      :city_id  => city.id,
      :created_at => Time.now
    }
    attrs[:start_time] = parse_time(city, data)
    raise "Не могу разобрать время #{data['date']} #{data['time']}" unless attrs[:start_time]
    attrs[:is_whole_day] = true if data["time"].blank?
    attrs[:finish_time] = attrs[:start_time] + data["period"]*60 if not attrs[:is_whole_day] and data["period"].to_i>0

    puts "* #{data['url']}"
    puts "  #{data['city']} #{data['date']} #{data['time']} -> #{attrs[:start_time]} (tz:#{city.time_zone}) -  #{attrs[:is_whole_day] ? 'whole day' : attrs[:finish_time]}"
    print "  #{data['category']}\t| #{attrs[:subject]}"
    if event = Event.first(
        :subject => attrs[:subject],
        :start_time => attrs[:start_time],
        :place => attrs[:place]
        )
      print " - DUP"
    else
      return nil unless event = create( attrs )
      # event.source = source
      # event.save
      # print "- CAN'T SAVE: #{event}"
    end

    if attrs[:image_url]
      uri = URI.parse(attrs[:image_url])
      image_path = "images/" + uri.host + uri.path
      ImageDownloader.download!(attrs[:image_url], image_path) if not File.file?(image_path)
    end
    
    print " = #{event.id}\n"
    event
  end

end
