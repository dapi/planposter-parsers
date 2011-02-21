# -*- coding: utf-8 -*-

set :application, "rotator.aydamaster.ru"
set :domain, "wwwdata@aydamaster.ru"
set :rails_env, "production"
set :deploy_to, "/home/wwwdata/rotator.aydamaster.ru"
set :local_link, 'danil@dapi.orionet.ru:/home/danil/code/rotator.aydamaster.ru'

revision = `git branch  | grep '*' | sed -e 's/* //'`.sub("\n",'') || 'production'
puts "Revision: #{revision}"
# set :revision,              revision
set :keep_releases,	3

set :repository, 'ssh://danil@dapi.orionet.ru/home/danil/code/rotator.aydamaster.ru/.git/'
set :web_command, "sudo apache2ctl"

set :shared_paths, {
  'log'    => 'log',
  'tmp'    => 'tmp'
}

  
namespace :vlad do

  desc "Full deployment cycle"
  task "deploy" => %w[
      vlad:update
      vlad:start_app
      vlad:cleanup
    ]

  remote_task :update do
    Rake::Task['vlad:copy_configs'].invoke
    Rake::Task['vlad:bundle_install'].invoke
  end
  
end
