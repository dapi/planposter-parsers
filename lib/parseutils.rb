# -*- coding: utf-8 -*-
$KCODE = 'u'
require 'rubygems'
require 'russian'
require 'json'
require 'ostruct'

class ParseUtils

  attr_accessor :debug, :index, :remove_after_load

  def initialize(remove_after_load=false)
    self.index = 0
    self.debug = false
  end

  def generate_filename event
    filename = event.uid
    filename = (event.url.is_a?(Array) ?  event.url.join(',') : event.url) + event.subject unless filename
    filename.gsub! event.source, ''
    filename.gsub! '/','-'
    filename = Russian.translit(filename).gsub(/[^a-z0-9\-_\,]/i,'_')
    filename.gsub! /_*(http|www)_*/, ''
    filename.gsub! /_+\./, '.'
    filename = filename.slice(0,70)
    filename.gsub! /__+/, '_'
    filename.gsub! /--+/, '-'
    zeros=(1..(6-event.index.to_s.length)).to_a.collect {'0'}.join
    "#{zeros}#{event.index}-" + filename + '.json'
  end

  def save_event event
    return unless event
    event.delete 'dump' unless debug
    event['index'] = self.index+=1
    event = OpenStruct.new event
    filename = generate_filename( event )
    File.open( './data/'+filename, 'w' ) do |f|
      print  "#{event.index}\t#{event.place} (#{event.category})\t#{event.subject}"
      print "\n"
      f.write event.marshal_dump.to_json
    end
  end

end
