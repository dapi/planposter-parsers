#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'curb'

@host_url = "http://www.kinopoisk.ru"

def easy_curl url
  doc = Curl::Easy.perform(url) do |curl|
    curl.headers["User-Agent"] = @USERAGENT
    curl.headers["Reffer"] = "http://www.kinopoisk.ru"
    curl.enable_cookies = true
    curl.cookiefile = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
    curl.cookiejar = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
  end
  return doc.body_str
end

easy_curl( [@host_url, 'level/9'].join('/') )
