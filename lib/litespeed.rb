#custom variables
set :ls_bin, '/opt/lsws/bin/lswsctrl' #where litespeed is located

desc "Overrides the default deploy:start"
deploy.task :start, :roles => :app do
   sudo "#{ls_bin} start"
end

desc "Overrides the default deploy:start"
deploy.task :stop, :roles => :app do
   sudo "#{ls_bin} stop"
end

desc "Overrides the default deploy:restart"
deploy.task :restart, :roles => :app do
   sudo "#{ls_bin} restart"
end

desc "Overrides the default deploy:spinnert"
deploy.task :spinner, :roles => :app do
   sudo "#{ls_bin} restart"
end

namespace :litespeed do
  
  desc <<-DESC
  Change out quizical for the applciation name.
  DESC
  task :configure do
    sudo "sed -i 's_/home/ec2admin/quizical_/mnt/ec2admin/#{application}_g' /opt/lsws/conf/httpd_config.xml"
    
    sudo "sed -i 's/quizical/#{application}/g' /opt/lsws/conf/httpd_config.xml"
    sudo "mv /opt/lsws/conf/quizical.xml /opt/lsws/conf/#{application}.xml"
    sudo "gem install ruby-lsapi"
  end
  
  desc <<-DESC
  Extend setup to allow group members to read files in our deployment directory. We do this because we
    run litespeed as a different user.
  DESC
  task :chmod_group do
    run "chmod g+w #{deploy_to}/ -R"
  end
end