#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'curb'

@USERAGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/534.21 (KHTML, like Gecko) Chrome/11.0.678.0 Safari/534.21"
@host_url = "http://eventful.com"

worldwide_location = "location_type=worldwide&location_id=worldwide&input_token=change_location&path=%2Fevents"

Curl::Easy.http_post('http://eventful.com/json/tools/location', worldwide_location) do |curl|
    curl.headers["User-Agent"] = @USERAGENT
    curl.headers["Reffer"] = @host_url
    curl.enable_cookies = true
    curl.cookiefile = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
    curl.cookiejar = File.expand_path(File.dirname(__FILE__) + "/cookie.txt")
end

