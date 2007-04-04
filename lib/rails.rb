
# Install ruby gems

def install_ruby_gems
  # TODO: make these hardcoded URLs variable so we can use the latest versions easily
  run <<-CMD
      wget http://rubyforge.org/frs/download.php/11289/rubygems-0.9.0.tgz &&
      tar -xvf rubygems-0.9.0.tgz
  CMD

  run "cd rubygems-0.9.0 && sudo ruby setup.rb" do |channel, stream, data|
      if data =~ /^Password:/
        channel.send_data "#{aws('user_password')}\n"
      end
  end

  #cleanup
  run "cd .. && rm ruby* -drf"
end

# Install rails
def install_rails
  sudo "gem install -y --no-rdoc --no-ri rails"
end

# Setup Database Configuration
def write_database_yaml #, :roles => :app do 
  # generate database configuration 
  database_configuration = render :template => <<-EOF 
defaults: &defaults
  adapter: #{aws('db_adapter')} 
  username: #{aws('db_user')}
  password: #{aws('db_password')}
  encoding: utf8 

development: 
  database: #{aws('application')}_development 
  <<: *defaults 

test: 
  database: #{aws('application')}_test 
  <<: *defaults

production: 
  database: #{aws('application')}_production 
  <<: *defaults
  EOF

  put database_configuration, "#{aws('current_release')}/config/database.yml", :mode => 0664
  sudo "chown -R #{aws('user')}:#{aws('group')} #{aws('current_release')}/config/database.yml" 
end