namespace :litespeed do
  
  desc <<-DESC
  Change out quizical for the applciation name.
  DESC
  task :configure do
    sudo "sed -i 's/quizical/#{application}/g' /opt/lsws/conf/httpd_config.xml"
    sudo "gem install ruby-lsapi"
  end
end