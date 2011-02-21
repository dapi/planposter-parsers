# -*- coding: utf-8 -*-
require 'models/category'

class Event
  include DataMapper::Resource

  property :id,          Serial
  property :subject,     String
  property :source,      String
  property :date,        Date
  property :time,        Time
  property :period,      Integer
  property :created_at,  DateTime
  property :address,     String
  property :creatory_id, Integer
  property :place,       String
  property :url,         String
  property :detail,      Text

  belongs_to :category

  def self.create_from_parser(source, data)
    category = Category.first :name=>data["category"]
    raise "Не найдена категория: #{data['category']} для #{data.inspect}" unless category

    create(
      :subject => data["subject"],
      :source => source,
      :date => data["date"],
      :time => data["time"],
      :period => data["period"],
      :address => data["address"],
      :place => data["place"],
      :detail => data["detail"],
      :url => data["url"],
      :category_id => category.id,
      :created_at => Time.now
      )
  end
  
end
