# -*- coding: utf-8 -*-
source 'http://rubygems.org'

gem 'dm-core'
gem 'dm-postgres-adapter'
gem 'dm-paperclip'

# gem 'dm-zone-types' - нам не нужно, потому что мы все записываем в utc

gem 'dm-counter-cache', :git => 'https://github.com/markiz/dm-counter-cache.git'
gem 'json'
gem 'i18n'
gem 'nokogiri'
gem 'russian'
gem 'curb'
gem 'carrierwave'
# gem 'hoptoad_notifier'

gem 'json'

# gem 'loop_dance', :path => '/home/danil/code/gems/loop_dance'

# Vlad не живет с синатрой
group :deploy do
  gem 'vlad', ">=2.1.0"
  gem "vlad-git"
  if `hostname`=~/dapi/
    gem 'vlad-helpers', :path => '/home/danil/code/gems/vlad-helpers/'
  else
    gem 'vlad-helpers', :git => 'git://github.com/dapi/vlad-helpers.git'
  end
  # gem "vlad-nginx"
end

group :test do
  gem 'rspec'
  gem 'rack-test', :require => 'rack/test'
  gem 'dm-migrations'
  gem 'dm-sqlite-adapter'
  gem 'rcov'
  gem 'capybara'
end
