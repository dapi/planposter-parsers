# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# require File.expand_path('../config/application', __FILE__)
require 'rubygems'
require 'rake'

namespace :vlad do
  task :deploy do
    deploy_to='wwwdata@planposter.com:planposter-parsers'
    # '.git' --exclude '.*' --exclude 'parsers/*/data*' --exclude 'cookie*' --exclude 'tmp/' --exclude 'Gem*'
    system "rsync --exclude-from=.gitignore  --delete --delete-excluded -vur  . #{deploy_to}"

  end
end

# Planposter::Application.load_tasks
