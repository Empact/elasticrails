# Restart server
def restart_server #, :roles => :app do 
  case server
    when 'litespeed'
      sudo "#{aws('ls_bin')} restart"
    else
      raise "unsupported server" 
    end  
end

# Start server" 
def start #, :roles => :app do
  case server
    when 'litespeed'
      on_rollback { sudo "#{aws('ls_bin')} stop" }
      sudo "#{aws('ls_bin')} start"
    else
      raise "unsupported server" 
    end

end

# Stop server" 
def stop #, :roles => :app do 
  case server
    when 'litespeed'
      on_rollback { sudo "#{aws('ls_bin')} stop" }
      sudo "#{aws('ls_bin')} stop"
    else
      raise "unsupported server" 
    end
end

# Patch the EC2 instance with any updates"
def patch_server #, :roles => :app do

  # generate the contents for an hourly cron job file
  hourly_cron = render :template => <<-EOF
#!/bin/bash
# This script should be called hourly

#backup the db to s3
cd /home/#{aws('user')}/#{aws('application')}/current
rake --trace RAILS_ENV=#{aws('mode')} s3:backup:db

#cleanup our old backups at s3
rake s3:manage:clean_up

#clearout our front page caches
rake s3:manage:delete_object BUCKET=#{aws('application')} PREFIX=#{aws('cache')}
EOF

   put hourly_cron, "/home/#{aws('user')}/#{aws('application')}_hourly.cron", :mode => 0754
   sudo "mv /home/#{aws('user')}/#{aws('application')}_hourly.cron /etc/cron.hourly/"
  sudo "chown -R root:root /etc/cron.hourly/#{aws('application')}_hourly.cron"
   
end

# Add the users and permissions we'll need on the server
def add_users
  #add some users
  sudo "/usr/sbin/useradd -g www #{aws('user_secondary')}"
  
  #create their passwords
  run <<-CMD
    echo "#{aws('user_secondary_password')}" | sudo passwd --stdin #{aws('user_secondary')}
  CMD
  
  #give full permissions to the primary user directory
  sudo "chmod g+rwx /home/#{aws('user')}"
end

# Restore db from S3 (using the s3.rake file)"
def import_db #, :roles => :db, :only => { :primary => true } do
    run <<-CMD 
      cd #{aws('current_path')} && 
      rake s3:retrieve:db &&
      tar -xvf #{aws('application')}.db.#{aws('mode')}.* &&
      mysql -u #{aws('db_user')} -p#{aws('db_password')} #{aws('application')}_#{aws('mode')} < tmp/#{aws('application')}.db.* &&
      rm #{aws('application')}.db.* &&
      rm tmp/#{aws('application')}.db.*
    CMD
end
