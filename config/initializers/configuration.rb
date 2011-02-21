set :logging, true
enable :raise_errors

configure(:development) do |config|
  config.also_reload 'models/*.rb'
  config.dont_reload 'config/**/*.rb'
end

configure(:prodiction) do
  log = File.new("./log/production.log", "a")
  STDOUT.reopen(log)
  STDERR.reopen(log)
end

@config = YAML.load(File.read('config/config.yml'))[Sinatra::Base.environment.to_s]

BASE_HOST = @config['host'] || ('http://'+`hostname`.gsub("\n",'')) unless defined?(BASE_HOST)
