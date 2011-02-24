#!/usr/bin/env ruby
require "rubygems"
$KCODE='u'

require 'json'

json = File.open(ARGV[0]).read
puts JSON.parse(json).inspect
