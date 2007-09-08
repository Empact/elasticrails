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

aws = Aws.new 
role :web, aws.access[:url] #or replace with your own url. ex: myapp.com
role :app, aws.access[:url]
role :db,  aws.access[:url], :primary => true

#database related
set :db_adapter, 'mysql'
set :db_user, 'YOUR-DATABASE-USER'
set :db_password, 'YOUR-DATABASE-PASSWORD'


after "deploy:setup", "rails:add_shared_config", "rails:install_dependencies", "litespeed:chmod_group"
after "deploy:update_code", "rails:write_database_yaml"

task :initial_deploy do
  setup_server
  #server.start
  install_app
end

desc "With a fresh EC2 instance, do all the prep work to get the app going"
task :install_app do
    mysql.create_databases
    deploy.setup
    deploy.cold
    #er.import_db
    #server.restart
  end

desc "Prep the server."
task :setup_server do
  #server.add_user # need to figure out a better way to do this later.
  server.permissions
  mysql.configure
  rails.install_ruby_gems
  rails.install
  case app_server
    when 'litespeed'
      litespeed.configure
  end
  server.patch
end