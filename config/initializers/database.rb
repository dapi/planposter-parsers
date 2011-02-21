DataMapper.setup(:default, @config['database_url'])

Dir["models/*.rb"].each{|f| require f}

DataMapper.finalize
