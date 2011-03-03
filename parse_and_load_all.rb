#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require 'config/boot'
require 'pathname'
require 'lib/parser_runner'
require 'lib/parseutils'

Pathname('./parsers/').children.each do |entry|
  if entry.directory?
    source = Source.first(:url => entry.basename)
    source = Source.create(:url => entry.basename) if not source
    if source.enabled
      parser_dir = "./parsers/#{entry.basename}/"
      parser_file = Pathname.glob(parser_dir+"[Pp]arser.*").pop
      if parser_file
        #
        # парсинг
        source.state = 'parsing'
        source.parsing_started_at = Time.now
        source.save
        begin
          system("./#{parser.basename}")
        rescue
          #puts 'parser error'
          source.parsing_result = 'parsing_error'
          source.parsing_finished_at = Time.now
          source.save
          next
        else
          source.parsing_result = 0
          source.parsing_finished_at = Time.now
          source.save
        end
        #
        # импорт 
        source.state='import'
        source.import_started_at = Time.now
        source.save
        ##
        parser = ParseUtils.new
        parser.remove_after_load = false
        imported_count = 0
        not_imported_count = 0
        Dir.glob(parser_dir+'data/*.json').sort.each do |file|
          begin
            parser.load_file file
          rescue Exception => e
            not_imported_count += 1
          else
            imported_count += 1
          end
        end
        ##
        source.state = 'wait'
        source.import_finished_at = Time.now
        source.imported_count = imported_count
        source.not_imported_count = not_imported_count
        source.save
      end
    end
  end
end
