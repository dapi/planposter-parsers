# -*- coding: utf-8 -*-
source 'http://rubygems.org'

gem 'sinatra'
gem 'dm-core'
gem 'dm-postgres-adapter'
gem 'dm-paperclip'
gem 'json'
gem 'i18n'
gem 'nokogiri'
# gem 'hoptoad_notifier'

gem 'json'

gem 'loop_dance', :path => '/home/danil/code/gems/loop_dance'

group :development do
  gem 'sinatra-reloader', :require => 'sinatra/reloader'
end

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
