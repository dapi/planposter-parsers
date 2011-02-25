#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
$KCODE='u'

require 'json'

json = File.open(ARGV[0]).read
data = JSON.parse(json)

puts "Загружено: " + data.count + "записей. Пример:"

# data[0].inspect
