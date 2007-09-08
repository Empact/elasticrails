namespace :server do
  desc <<-DESC
  Restart the server
  DESC
  task :restart, :roles => :app do 
    case app_server
      when 'litespeed'
        sudo "#{ls_bin} restart"
      else
        raise "unsupported server" 
      end  
  end

  desc <<-DESC
  Start the server.
  DESC
  task :start, :roles => :app do
    case app_server
      when 'litespeed'
        on_rollback { sudo "#{ls_bin} stop" }
        sudo "#{ls_bin} start"
      else
        raise "unsupported server" 
      end

  end

  task :stop, :roles => :app do 
    case app_server
      when 'litespeed'
        on_rollback { sudo "#{ls_bin} stop" }
        sudo "#{aws('ls_bin')} stop"
      else
        raise "unsupported server" 
      end
  end

  desc <<-DESC
  Write patches to the server.
  DESC
  task :patch, :roles => :app do
    # generate the contents for an hourly cron job file
    hourly_cron = <<-EOF
  #!/bin/bash
  # This script should be called hourly

  #backup the db to s3
  cd /home/#{user}/#{application}/current
  rake --trace RAILS_ENV=production s3:backup:db

  #cleanup our old backups at s3
  rake s3:manage:clean_up

  EOF

    put hourly_cron, "/home/#{user}/#{application}_hourly.cron", :mode => 0754
    sudo "mv /home/#{user}/#{application}_hourly.cron /etc/cron.hourly/"
    sudo "chown -R root:root /etc/cron.hourly/#{application}_hourly.cron"
   
  end

  desc <<-DESC
  A user (ec2admin) is pre-created on the image. This task adds a new
  user to the image. The ec2admin user is then deleted.
  DESC
  task :add_user do
    #add the defined user. 
    #the ec2admin is pre-created user on the image.
    #sudo "-u ec2admin /usr/sbin/useradd -g www #{user}" 
    #sudo "/usr/sbin/useradd -g www #{aws('user_secondary')}"
  
    #create their passwords
    #sudo <<-CMD
    #  -u ec2admin &&
    #  echo "#{user_password}" | sudo passwd --stdin #{user}
    #CMD
  
    #give full permissions to the primary user directory
    
  end
  
  task :permissions do
    sudo "chown -R ec2admin.www /mnt/"
    sudo "-u ec2admin chmod g+rwx /mnt/"
  end

  desc <<-DESC
  Import your database from s3. the database got there from our backup routines.
  DESC
  task :import_db, :roles => :db, :only => { :primary => true } do
      run <<-CMD 
        cd #{aws('current_path')} && 
        rake s3:retrieve:db &&
        tar -xvf #{aws('application')}.db.#{aws('mode')}.* &&
        mysql -u #{aws('db_user')} -p#{aws('db_password')} #{aws('application')}_#{aws('mode')} < tmp/#{aws('application')}.db.* &&
        rm #{aws('application')}.db.* &&
        rm tmp/#{aws('application')}.db.*
      CMD
  end
end