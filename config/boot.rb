$environment = ENV['RACK_ENV'] ||= "development"

require 'bundler/setup'

Bundler.require(:default)
Bundler.require($environment)

@config = YAML.load(File.read('config/config.yml'))[$environment]
DataMapper.setup(:default, @config['database_url'])
Dir["models/*.rb"].each{|f| require f}
DataMapper.finalize
