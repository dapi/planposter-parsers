# -*- coding: utf-8 -*-
class City
  include DataMapper::Resource

  property :id,       Serial
  property :name,     String

  has n, :events
  
end
