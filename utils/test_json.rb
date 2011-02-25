#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
$KCODE='u'

require 'json'

json = File.open(ARGV[0]).read
data = JSON.parse(json)

data.delete "dump"
puts data.inspect
