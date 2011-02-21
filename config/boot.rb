ENV['RACK_ENV'] ||= "development"

require 'bundler/setup'

Bundler.require(:default)
Bundler.require(Sinatra::Base.environment)

require 'config/initializers/configuration'
require 'config/initializers/database'

set :public, 'public'
