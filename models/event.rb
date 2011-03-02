# -*- coding: utf-8 -*-
require 'models/category'
require 'models/city'

class Event
  include DataMapper::Resource

  property :id,          Serial
  # property :uid,         String
  property :subject,     String
  property :url,         String
  property :source,      String
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

  belongs_to :category
  belongs_to :city

  def self.concat(date,time)
    time = Time.parse time
    Time.local(date.year, date.month, date.day,
      time.hour, time.min)
  end

  def self.create_from_parser(data)
    raise "Не указана категория" if data["category"].blank?
    raise "Не указан город" if data["city"].blank?
    if data["date"].blank?
      print "Не указана дата, пока такие не обрабатываем"
      return
    end

    category = Category.first( :name=>data["category"]) || Category.create(:name=>data["category"])
    # raise "Не найдена категория: #{data['category']} для #{data.inspect}" unless category
    city  = City.first(:name=>data["city"]) || City.create(:name=>data["city"])
    data["subject"] = data["subject"].gsub('http://','').gsub('/','')
    data.each_key do |key|
      data[key].strip! if data[key].is_a? String
    end
    attrs = {
      :subject => data["subject"],
      :source => data["source"],
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
      # print "- CAN'T SAVE: #{event}"
    end
    print " = #{event.id}\n"
    event
  end

end
