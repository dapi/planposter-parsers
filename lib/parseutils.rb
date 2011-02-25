# -*- coding: utf-8 -*-
$KCODE = 'u'
require 'rubygems'
require 'russian'
require 'json'
require 'ostruct'

module ParseUtils
  
  class << self
    
    attr_accessor :debug
    
    def generate_filename event
      filename = event.uid
      filename = (event.url.is_a?(Array) ?  event.url.join(',') : event.url) + event.subject unless filename
      filename.gsub! event.source, ''
      filename = Russian.translit(filename).gsub(/[^a-z0-9\-_\,]/i,'_')
      filename.gsub! /_*(http|www)_*/, ''
      filename.gsub! /__+/, '_'
      filename.gsub! /_+\./, '.'
      raise "Не указан id или url для события" unless filename
      filename + '.json'
    end
  
    def save_event event
      event.delete 'debug' unless debug
      event = OpenStruct.new event
      filename = generate_filename(event)
      File.open( './data/'+filename, 'w' ) do |f|
        print  event.category, "\t", event.place, "\t", event.subject
        print "\n"
        f.write event.to_hash.to_json
      end
    end
  end
  
 end
