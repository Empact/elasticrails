
#Customize our litespeed configuration files
def configure_litespeed
  sudo "sed -i 's/quizical/#{aws('application')}/g' /opt/lsws/conf/httpd_config.xml"
  sudo "gem install ruby-lsapi"
end