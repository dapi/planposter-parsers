#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'curb'

@USERAGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/534.21 (KHTML, like Gecko) Chrome/11.0.678.0 Safari/534.21"
@host_url = "http://ticketmaster.com"

def easy_curl url
  doc = Curl::Easy.perform(url) do |curl|
    curl.headers["User-Agent"] = @USERAGENT
    curl.headers["Reffer"] = @host_url
    curl.enable_cookies = true
    curl.cookiefile = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
    curl.cookiejar = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
    curl.timeout = 30
    curl.follow_location = true
    curl.max_redirects = 5
  end
  return doc.body_str
end

easy_curl(@host_url)
