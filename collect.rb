#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# Запускать: ./collector.rb [./parsers/test/parser.rb]
# Без параметра обрабатывает все парсеры в parsers/
#

# $: << File.expand_path(File.dirname(__FILE__))
require "rubygems"
require 'config/boot'
require 'lib/parser_runner'
require 'lib/parseutils'

parser = ParseUtils.new
parser.remove_after_load = false

calculate_only = false

dirs = ARGV

if dirs.empty?
  puts "Запускать так: ./collect.rb ./parsers/*/data/"
end

all_count=0
dirs.each do |dir|
  if File.directory?(dir)
    count=0
    Dir.glob(dir+'*.json').sort.each do |file|
      parser.load_file file unless calculate_only
      count+=1
      all_count+=1
    end
    puts "#{dir} #{count} файлов"
  else
    parser.load_file dir  unless calculate_only
    all_count+=1
  end
end

puts "Всего #{all_count} файлов"


# if ARGV[0]
#   r = ParserRunner.new ARGV[0]
#   r.run
# else
#   Dir.glob('./parsers/*/parser*').each do |parser|
#     r = ParserRunner.new parser
#     r.run
#   end
# end
