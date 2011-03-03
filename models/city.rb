# -*- coding: utf-8 -*-
class City
  include DataMapper::Resource

  property :id,       Serial
  property :name,     String
  property :events_count, Integer, :default => 0

  has n, :events

end
