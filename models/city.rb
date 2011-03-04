# -*- coding: utf-8 -*-
class City
  include DataMapper::Resource

  property :id,       Serial
  property :name,     String
  property :events_count, Integer, :default => 0

  has n, :events

  # TODO перейдет в параметр города
  def time_zone
    3
  end

  def time_zone_in_seconds
    time_zone * 60 * 60
  end

end
