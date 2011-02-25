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
  property :time,        String
  property :created_at,  Time
  property :period,      Integer
  property :address,     String
  property :category_id, Integer
  property :city_id,     Integer
  property :place,       String
  property :details,     Text

  belongs_to :category
  belongs_to :city

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
    attrs = {
      :subject => data["subject"],
      :source => data["source"],
      :date => data["date"],
      :period => data["period"],
      :address => data["address"],
      :place => data["place"],
      :details => data["details"],
      :url => data["url"],
      :category_id => category.id,
      :city_id  => city.id,
      :created_at => Time.now
    }
    attrs[:time] = data["time"] unless data["time"].blank?
    print "#{attrs[:date]} #{attrs[:time] || '-'} #{data['place']} (#{data['category']})\t| #{attrs[:subject]}"
    if event = Event.first(
        :subject => attrs[:subject],
        :date => attrs[:date],
        :time => attrs[:time],
        :place => attrs[:place]
        )
      print " - DUP"
    else
      event = create( attrs )
      # print "- CAN'T SAVE: #{event}"
    end
    print " = #{event.id}\n"
  end
  
end
