# -*- coding: utf-8 -*-
require 'models/category'
require 'models/city'
require 'models/source'

require 'lib/image_uploader'
require 'uri'

class Event
  include DataMapper::Resource
  include DataMapper::CounterCacheable

  property :id,          Serial
  # property :uid,         String
  property :subject,     String
  property :url,         String
  property :source_id,   Integer
  property :date,        Date
  property :start_time,  Time
  property :finish_time, Time
  property :created_at,  Time
  property :address,     String
  property :category_id, Integer
  property :city_id,     Integer
  property :place,       String
  property :image_url,   String
  property :details,     Text

  belongs_to :category, :counter_cache=>true
  belongs_to :city, :counter_cache=>true
  belongs_to :source, :counter_cache=>true

  def self.concat(date,time)
    time = Time.parse time
    Time.local(date.year, date.month, date.day,
      time.hour, time.min)
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
      :date => data["date"],
      :address => data["address"],
      :place => data["place"],
      :details => data["details"],
      :url => data["url"],
      :image_url => data["image_url"],
      :category_id => category.id,
      :city_id  => city.id,
      :created_at => Time.now
    }
    attrs[:date] = Date.parse data["date"]
    attrs[:start_time] = concat(attrs[:date], data["time"]) unless data["time"].blank? and attrs[:date].blank?
    attrs[:finish_time] = attrs[:start_time] + data["period"]*60 if attrs[:start_time] and data["period"].to_i>0

    print "#{attrs[:date]} #{attrs[:start_time] || '-'} #{data['place']} (#{data['category']})\t| #{attrs[:subject]}"
    if event = Event.first(
        :subject => attrs[:subject],
        :date => attrs[:date],
        :start_time => attrs[:start_time],
        :place => attrs[:place]
        )
      print " - DUP"
    else
      return nil unless event = create( attrs )
      # event.source = source
      # event.save
      # print "- CAN'T SAVE: #{event}"
      if attrs[:image_url]
        image = ImageUploader.new
        uri = URI.parse(attrs[:image_url])
        image.cache_dir = "images/" + uri.host
        image.cache_name = uri.path
        image_path = image.cache_dir + image.cache_name
        image.download!(attrs[:image_url]) if not File.file?(image_path)
      end
    end
    print " = #{event.id}\n"
    event
  end

end
