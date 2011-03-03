#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require 'config/boot'
require 'pathname'
require 'lib/parser_runner'
require 'lib/parseutils'

Pathname('./parsers/').children.each do |entry|
  next unless entry.directory?
  if (source=Source.first_or_create(:url => entry.basename)).enabled
    debugger
    puts "Обарбатываю источник: #{source.url}"
    Dir.chdir entry.to_s
    parser_file = Pathname.glob("[Pp]arser.*").pop or next
    source.run_parser(parser_file)
    source.collect_data if source.state=='parsing_ok'
  else
    puts "Источник не разрешен: #{source.url}"
  end
end
