require 'erb'
require 'rubygems'

#Load all of our library files
Dir[File.join(File.dirname(__FILE__), 'lib/*.rb')].each { |f| eval File.read(f) }

# user info
set :user, 'YOUR-USER'
set :user_password, "YOUR-PASSWORD"
set :server, 'litespeed' #more server support coming later
set :application, 'YOUR-APPLICATION-NAME'
set :deploy_to, "/mnt/#{user}/#{application}"

set :repository,'YOUR-REPOSITORY-URL'
set :scm_password, 'YOUR-REPOSITORY-PASSWORD'
set :scm_username, 'YOUR-REPOSITORY-USERNAME'

#EC2 SPECIFIC
@domain = 'YOUR-DOMAIN'
role :web, @domain 
role :app, @domain
role :db,  @domain, :primary => true

#database related
set :db_adaptor, 'mysql'
set :db_user, 'YOUR-DATABASE-USER'
set :db_password, 'YOUR-DATABASE-PASSWORD'

#custom variables
set :ls_bin, '/opt/lsws/bin/lswsctrl' #where litespeed is located


after "deploy:update_code", :setup_database_yaml
after "deploy:setup", :add_config_dir, :install_dependencies

task :initial_deploy do
  setup_server
  initial_install
end

task :login do
  er.login
end

desc "After creating an EC2 instance, do all the things needed to get the app going."
task :initial_install do
  er.patch_server
  er.start
  er.install_app
end

desc "With a fresh EC2 instance, do all the prep work to get the app going"
task :install_app do
    er.create_databases
    deploy.setup
    deploy.cold
    #er.write_database_yaml
    #er.migrate
    #er.import_db
    #er.restart_server
end

desc "create a place to keep our shared database.yml"
task :add_config_dir do
  run "mkdir -p #{shared_path}/config" 
end

task :setup_database_yaml do
  er.write_database_yaml
  run <<-CMD
      ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml
  CMD
end

#customize for your server
deploy.task :restart, :roles => :app do
   sudo "#{ls_bin} restart"
end

#customize for your server
deploy.task :spinner, :roles => :app do
   sudo "#{ls_bin} restart"
end

#install software specific to your applications
task :install_dependencies do
  #sudo "gem install -y fastercsv"
end


desc <<-DESC
Extend setup to allow group members to read files in our deployment directory. We do this because we
  run litespeed as a different user.
DESC
task :after_setup do
  run "chmod g+w #{deploy_to}/ -R"
end

desc <<-DESC
Sets up my server just how I want it.
DESC
task :setup_server do
  utilities.add_users
  er.configure_mysql
  er.install_ruby_gems
  er.install_rails
  case server
    when 'litespeed'
      er.configure_litespeed
    else
      raise "unsupported server" 
    end
end