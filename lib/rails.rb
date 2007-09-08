namespace :rails do

  desc "Install ruby gems"
  task :install_ruby_gems do
    # TODO: make these hardcoded URLs variable so we can use the latest versions easily
    run <<-CMD
        wget http://rubyforge.org/frs/download.php/11289/rubygems-0.9.0.tgz &&
        tar -xvf rubygems-0.9.0.tgz
    CMD

    run "cd rubygems-0.9.0 && sudo ruby setup.rb" do |channel, stream, data|
        if data =~ /^Password:/
          channel.send_data "#{user_password}\n"
        end
    end

    #cleanup
    run "cd .. && rm ruby* -drf"
  end

  # Install rails
  task :install do
    sudo "gem install -y --no-rdoc --no-ri rails"
  end

  # Setup Database Configuration
  task :write_database_yaml do
    database_configuration = <<-EOF
  defaults: &defaults
    adapter: #{db_adapter} 
    username: #{db_user}
    password: #{db_password}
    encoding: utf8 

  development: 
    database: #{application}_development 
    <<: *defaults 

  test: 
    database: #{application}_test 
    <<: *defaults

  production: 
    database: #{application}_production 
    <<: *defaults
  EOF
  
    #run "mkdir -p #{shared_path}/config" 
    put database_configuration, "#{shared_path}/config/database.yml", :mode => 0664
    sudo "chown -R #{user}:www #{shared_path}/config/database.yml"
    
    run <<-CMD
        ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml
    CMD
  end
  
  desc "create a place to keep our shared database.yml"
  task :add_shared_config do
    run "mkdir -p #{shared_path}/config" 
  end
  
  desc "install software specific to your applications"
  task :install_dependencies do
    #sudo "gem install -y ruby-openid"
  end
end