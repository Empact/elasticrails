# ----------------------------------------------------------
# mysql related tasks
# ----------------------------------------------------------
  # create the databases
  def create_databases #, :roles => :db, :only => { :primary => true } do
    on_rollback do 
      run <<-CMD
        mysqladmin -u #{aws('db_user')} -p#{aws('db_password')} drop #{aws('application')}_development &&
        mysqladmin -u #{aws('db_user')} -p#{aws('db_password')} drop #{aws('application')}_test &&
        mysqladmin -u #{aws('db_user')} -p#{aws('db_password')} drop #{aws('application')}_production
      CMD
    end
    run <<-CMD
      mysqladmin -u #{aws('db_user')} -p#{aws('db_password')} create #{aws('application')}_development &&
      mysqladmin -u #{aws('db_user')} -p#{aws('db_password')} create #{aws('application')}_test &&
      mysqladmin -u #{aws('db_user')} -p#{aws('db_password')} create #{aws('application')}_production
    CMD
  end
  
  # Configure mysql
  def configure_mysql
    #Create new data directory on mnt/. We can easily run out of room on sda1.
    #sudo "mkdir /mnt/mysql_db"
    #sudo "chown #{user}.www /mnt/mysql_db/"
    #Note, you must have a user on you local system with the same name as your capistrano user
    #put File.read("#{BASE}/config/my.cnf"), "/home/#{user}/my.cnf"
    #sudo "mv /home/#{user}/my.cnf /etc/my.cnf"

    sudo "/sbin/service mysqld start" 
    sudo <<-CMD
      mysqladmin -u root password #{aws('db_password')}
    CMD

    sudo <<-CMD
      mysql -u root -p#{aws('db_password')} -e "GRANT ALL PRIVILEGES ON *.* TO '#{aws('db_user')}'@'%' IDENTIFIED BY '#{aws('db_password')}' WITH GRANT OPTION;" &&
      mysql -u root -p#{aws('db_password')} -e "GRANT ALL PRIVILEGES ON *.* TO '#{aws('secondary_user')}'@'%' IDENTIFIED BY '#{aws('secondary_password')}' WITH GRANT OPTION;" &&
      mysql -u root -p#{aws('db_password')} -e "GRANT ALL PRIVILEGES ON *.* TO '#{aws('db_user')}'@'localhost' IDENTIFIED BY '#{aws('db_password')}' WITH GRANT OPTION;" &&
      mysql -u root -p#{aws('db_password')} -e "GRANT ALL PRIVILEGES ON *.* TO '#{aws('secondary_user')}'@'localhost' IDENTIFIED BY '#{aws('secondary_password')}' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    CMD

    sudo "/sbin/chkconfig mysqld on"

  end