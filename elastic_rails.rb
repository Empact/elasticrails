require 'yaml'
require 'erb'
require 'rubygems'
require_gem 'amazon-ec2'
require 'capistrano'

Capistrano.configuration(:must_exist).load do 
  
  @er_config ||= YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), '/config/aws.yml'))).result)
  
  set :user, @er_config['user'] unless user
  set :server, @er_config['server']
  set :application, @er_config['application'] unless application
  set :deploy_to, "/home/#{@er_config['user']}/#{application}"
  set :repository, @er_config['repository'] unless repository
  set :

  role :web, @er_config['url'] if roles[:web].empty?
  role :app, @er_config['url'] if roles[:app].empty?
  role :db,  @er_config['url'], :primary => true if roles[:db].empty?
  
  
 # The actor methods in the /lib recipe files can not be called directly by Capistrano
  # using cap 'method'. If you would like to call these actor methods using the 'cap'
  # command, add them here, like so:
  # task :my_new_cap_command do
  #  aws.my_actor_method
  # end
  
  task :complete_bundle do
    er.copy_keys
    er.complete_bundle
  end
  
  task :instances do
    er.instances
  end
  
  task :images do
    er.images
  end
  
  task :launch_instance do
    image ||= 'ami-08806561'
    er.launch_instance(image)
  end
  
  task :initial_deploy do
    setup_server
    initial_install
  end
  
  task :terminate do
    begin
    er.terminate(instance)
    rescue
      puts "You need to pass in the instance id. Example - cap terminate -s instance=i-fc678395"
    end
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
      setup
      deploy
      er.write_database_yaml
      er.migrate
      er.import_db
      er.restart_server
  end
  
  # this needs to stay here so cap knows the right restart to use
  task :restart do
    er.restart_server
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
    er.add_users
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
end


module ElasticRails
  require 'breakpoint'

# All recipe files go in lib. Adding new recipes is a simple 
# as adding new files in lib
Dir[File.join(File.dirname(__FILE__), '/lib/*.rb')].each { |f| eval File.read(f) }

# Check to see if the variable is set in deploy.rb. If not, grab it elastic_rails/config/aws.yml
# Is this a good decision? Should I make users set their cap variables in deploy.rb? I preferred
# not to overwrite the existing deploy.rb file. But I wanted to make it as easy for new users to
# set up a deployment. A yaml seemed right, particularly for the AWS credentials. Having that in
# a yaml, then it was a quick jump to put more deployment variables in the yaml. Users can still
# use deploy.rb to set their variables, but they can also use the yaml. Deploy.rb variables have
# preference.

  def aws(set)
    er_config = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), '/config/aws.yml'))).result)
    eval set rescue er_config[set]
  end

  
end
Capistrano.plugin :er, ElasticRails
