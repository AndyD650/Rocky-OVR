#***** BEGIN LICENSE BLOCK *****
#
#Version: RTV Public License 1.0
#
#The contents of this file are subject to the RTV Public License Version 1.0 (the
#"License"); you may not use this file except in compliance with the License. You
#may obtain a copy of the License at: http://www.osdv.org/license12b/
#
#Software distributed under the License is distributed on an "AS IS" basis,
#WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
#specific language governing rights and limitations under the License.
#
#The Original Code is the Online Voter Registration Assistant and Partner Portal.
#
#The Initial Developer of the Original Code is Rock The Vote. Portions created by
#RockTheVote are Copyright (C) RockTheVote. All Rights Reserved. The Original
#Code contains portions Copyright [2008] Open Source Digital Voting Foundation,
#and such portions are licensed to you under this license by Rock the Vote under
#permission of Open Source Digital Voting Foundation.  All Rights Reserved.
#
#Contributor(s): Open Source Digital Voting Foundation, RockTheVote,
#                Pivotal Labs, Oregon State University Open Source Lab.
#
#***** END LICENSE BLOCK *****

require 'dotenv'
Dotenv.load



set :application, "rocky"
set :repository,  "git@github.com:trustthevote/Rocky.git"

# If you have previously been relying upon the code to start, stop
# and restart your mongrel application, or if you rely on the database
# migration code, please uncomment the lines you require below

# If you are deploying a rails app you probably need these:

# load 'ext/rails-database-migrations.rb'
# load 'ext/rails-shared-directories.rb'

# There are also new utility libaries shipped with the core these
# include the following, please see individual files for more
# documentation, or run `cap -vT` with the following lines commented
# out to see what they make available.

# load 'ext/spinner.rb'              # Designed for use with script/spin
# load 'ext/passenger-mod-rails.rb'  # Restart task for use with mod_rails
# load 'ext/web-disable-enable.rb'   # Gives you web:disable and web:enable


set :deploy_to, ENV['DEPLOY_TO']

set :stages, Dir["config/deploy/*"].map {|stage| File.basename(stage, '.rb')}
set :default_stage, "production"
require 'capistrano/ext/multistage'

set :scm, "git"
set :user, "rocky"
set :deploy_via, :remote_cache
set :branch, (rev rescue "master")    # cap deploy -Srev=[branch|tag|SHA1]

set :group_writable, false
set :use_sudo, false


set :rvm_ruby_string, :local        # use the same ruby as used locally for deployment
set :rvm_autolibs_flag, "enable"
set :rvm_install_with_sudo, true 

before 'deploy:setup', 'rvm:install_rvm'   # install RVM
before 'deploy:setup', 'rvm:install_ruby' 

before 'deploy', 'rvm:install_ruby' # install Ruby and create gemset (both if missing)

require "rvm/capistrano"



after "deploy:update_code", "deploy:symlink_configs", "deploy:symlink_pdf", "deploy:symlink_csv", "deploy:symlink_partners"

set :rake, 'bundle exec rake'

after "deploy:symlink_configs", "deploy:symlink_state_configs", "deploy:symlink_mobile_configs", "deploy:symlink_app_configs"
before "deploy:restart", "deploy:import_states_yml"   # runs after migrations when migrating
after "deploy:restart", "deploy:run_workers"
after "deploy", "deploy:cleanup"

namespace :admin do
  desc "reset admin password and display"
  task :reset_password, :roles => [:app] do
    run <<-CMD
      cd #{latest_release} &&
      bundle exec rake admin:reset_password
    CMD
  end
end

namespace :deploy do
  desc "import states.yml data"
  task :import_states_yml, :roles => [:app] do
    run <<-CMD
      cd #{latest_release} &&
      bundle exec rake import:states
    CMD
  end

  desc "Link the database.yml, .env.{environment} files, and newrelic.yml files into the current release path."
  task :symlink_configs, :roles => [:app, :util], :except => {:no_release => true} do
    run <<-CMD
      cd #{latest_release} &&
      ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/database.yml
    CMD
    run <<-CMD
      cd #{latest_release} &&
      ln -nfs #{shared_path}/config/newrelic.yml #{latest_release}/config/newrelic.yml
    CMD
    run <<-CMD
      cd #{latest_release} &&
      ln -nfs #{shared_path}/.env.#{rails_env} #{latest_release}/.env.#{rails_env}
    CMD
  end
  
  desc "Link the states_with_online_registration.yml into the current release path. Create from the example if it doesn't exist"
  task :symlink_state_configs, :roles=>[:app, :util], :except => {:no_release => true} do
    run <<-CMD
      cd #{latest_release} &&
      cp -n #{latest_release}/config/states_with_online_registration.yml.example #{shared_path}/config/states_with_online_registration.yml
    CMD
    run <<-CMD
      cd #{latest_release} &&
      ln -nfs #{shared_path}/config/states_with_online_registration.yml #{latest_release}/config/states_with_online_registration.yml
    CMD
  end
  
  desc "Link the mobile.yml configuration into the current release path. Create from the example if it doesn't exist"
  task :symlink_mobile_configs, :roles=>[:app, :util], :except => {:no_release => true} do
    run <<-CMD
      cd #{latest_release} &&
      cp -n #{latest_release}/config/mobile.yml.example #{shared_path}/config/mobile.yml
    CMD
    run <<-CMD
      cd #{latest_release} &&
      ln -nfs #{shared_path}/config/mobile.yml #{latest_release}/config/mobile.yml
    CMD
  end

  desc "Link the app_config.yml configuration into the current release path. Create from the example if it doesn't exist"
  task :symlink_app_configs, :roles=>[:app, :util], :except => {:no_release => true} do
    run <<-CMD
      cd #{latest_release} &&
      cp -n #{latest_release}/config/app_config.yml.example #{shared_path}/config/app_config.yml
    CMD
    run <<-CMD
      cd #{latest_release} &&
      ln -nfs #{shared_path}/config/app_config.yml #{latest_release}/config/app_config.yml
    CMD
  end


  desc "Link the pdf dir to /data/rocky/pdf"
  task :symlink_pdf, :roles => [:util], :except => {:no_release => true} do
    run <<-CMD
      cd #{latest_release} &&
      rm -rf pdf &&
      ln -nfs  #{ENV['SYMLINK_DATA_DIR']}/html pdf
    CMD
  end
  
  desc "Link the csv dir to /data/rocky/csv"
  task :symlink_csv, :roles => [:util], :except => {:no_release => true} do
    run <<-CMD
      cd #{latest_release} &&
      rm -rf csv &&
      ln -nfs #{ENV['SYMLINK_DATA_DIR']}/html/partner_csv csv
    CMD
  end


  desc "Link the public/partners dir to the shared path"
  task :symlink_partners, :roles=>[:app], :except => {:no_release => true} do
    run <<-CMD
      mkdir -p #{shared_path}/partner_assets &&
      cd #{latest_release} &&
      ln -nfs #{shared_path}/partner_assets #{latest_release}/public/partners
    CMD
  end

  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  desc "Run (or restart) worker processes on util server"
  task :run_workers, :roles => :util do
    run "cd #{latest_release} && bundle exec ruby script/rocky_runner stop"
    run "cd #{latest_release} && bundle exec ruby script/rocky_pdf_runner stop"
    # nasty hack to make sure it stops
    run "pkill -f com.pivotallabs.rocky.PdfServer" rescue nil
    sleep 5
    run "cd #{latest_release} && bundle exec ruby script/rocky_pdf_runner start"
    run "cd #{latest_release} && bundle exec ruby script/rocky_runner start"
    unset(:latest_release)
  end

  desc "Stop worker processes on util server"
  task :stop_workers, :roles => :util do
    run "cd #{latest_release} && bundle exec ruby script/rocky_runner stop"
    run "cd #{latest_release} && bundle exec ruby script/rocky_pdf_runner stop"
    # nasty hack to make sure it stops
    run "pkill -f com.pivotallabs.rocky.PdfServer" rescue nil
    unset(:latest_release)
  end
end

# TODO: Is this ever used ?
# namespace :import do
#   desc "Upload state data from CSV_FILE and restart server"
#   task :states, :roles => :app do
#     local_path = ENV['CSV_FILE'] || 'states.csv'
#     remote_dir = File.join(shared_path, "uploads")
#     remote_path = File.join(remote_dir, File.basename(local_path))
#     run "mkdir -p #{remote_dir}"
#     top.upload local_path, remote_path, :via => :scp
#     run "cd #{current_path} && bundle exec rake import:states CSV_FILE=#{remote_path}"
#     find_and_execute_task "deploy:restart"
#   end
# end


require './config/boot'

require 'airbrake/capistrano'

require 'bundler/capistrano'
