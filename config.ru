$: << File.expand_path(File.dirname(__FILE__))

require 'web_server'
run Sinatra::Application
