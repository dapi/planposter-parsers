#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$: << File.expand_path(File.dirname(__FILE__))
require "rubygems"
require 'config/boot'

# PARSERS_DIR='./parsers/'

def load_events(events)
  puts "Событий #{events.count}"
  events.each do |event|
    Event.create_from_parser event
  end
end

def run_parser(parser_name)
  puts "Запускаю парсер #{parser_name}"
  # http://tech.natemurray.com/2007/03/ruby-shell-commands.html
  data = `#{parser_name}`
  if $?==0
    puts "Результат: ok. Разбираю.."
    load_events JSON.parse(data)
  else
    puts "Ошибка: #{$?}"
  end
end

if ARGV[0]
  run_parser(ARGV[0])
else
  puts "Запускать: ./collector.rb ./parsers/test/parser.rb"
end
