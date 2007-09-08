namespace :mysql do
  task :create_databases do #, :roles => :db, :only => { :primary => true } do
    on_rollback do 
      run <<-CMD
        mysqladmin -u #{db_user} -p#{db_password} drop #{application}_development &&
        mysqladmin -u #{db_user} -p#{db_password} drop #{application}_test &&
        mysqladmin -u #{db_user} -p#{db_password} drop #{application}_production
      CMD
    end
    run <<-CMD
      mysqladmin -u #{db_user} -p#{db_password} create #{application}_development &&
      mysqladmin -u #{db_user} -p#{db_password} create #{application}_test &&
      mysqladmin -u #{db_user} -p#{db_password} create #{application}_production
    CMD
  end
  
  # Configure mysql
  task :configure do
    #Create new data directory on mnt/. We can easily run out of room on sda1.
    #sudo "mkdir /mnt/mysql_db"
    #sudo "chown #{user}.www /mnt/mysql_db/"
    #Note, you must have a user on you local system with the same name as your capistrano user
    #put File.read("#{BASE}/config/my.cnf"), "/home/#{user}/my.cnf"
    #sudo "mv /home/#{user}/my.cnf /etc/my.cnf"

    sudo "/sbin/service mysqld start" 
    sudo <<-CMD
      mysqladmin -u root password #{db_password}
    CMD

    sudo <<-CMD
      mysql -u root -p#{db_password} -e "GRANT ALL PRIVILEGES ON *.* TO '#{db_user}'@'%' IDENTIFIED BY '#{db_password}' WITH GRANT OPTION;" &&
      mysql -u root -p#{db_password} -e "GRANT ALL PRIVILEGES ON *.* TO '#{db_user}'@'localhost' IDENTIFIED BY '#{db_password}' WITH GRANT OPTION;"
      CMD

    sudo "/sbin/chkconfig mysqld on"
    
    #TODO: Add to new updated image
    sudo "chown -R mysql.mysql /mnt/mysql_db"

  end
  
end