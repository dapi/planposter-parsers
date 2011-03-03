# -*- coding: utf-8 -*-

class Source
  include DataMapper::Resource

  property :id,          Serial
  property :url,         String
  property :enabled,     Boolean
  property :state,       String
  property :parsing_started_at, Time
  property :parsing_finished_at, Time
  property :parsing_result, Integer
  property :import_started_at, Time
  property :import_finished_at, Time
  property :imported_count, Integer
  property :not_imported_count, Integer
  property :events_count, Integer, :default => 0

  has n, :events

end
