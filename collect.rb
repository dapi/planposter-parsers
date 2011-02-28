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
ARGV.each do |dir|
  if File.directory?(dir)
    Dir.glob(dir+'*.json').sort.each do |file|
      parser.load_file file
    end
  else
    parser.load_file dir
  end
  
end

# if ARGV[0]
#   r = ParserRunner.new ARGV[0]
#   r.run
# else
#   Dir.glob('./parsers/*/parser*').each do |parser|
#     r = ParserRunner.new parser
#     r.run
#   end
# end
