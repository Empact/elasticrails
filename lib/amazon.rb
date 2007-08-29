namespace :ec2 do
  desc "initialize the AWS variable"
  task :aws do
   @aws = Aws.new
  end
  
  task :login do
    @aws.bash "ssh -i #{@aws.key[:path]+"id_rsa-" + @aws.key[:name]} #{user}@#{@aws.access[:url]}"
  end
   
  desc "return your own amazon images."
  task :images do
    @aws.connect.describe_images(:owner_id => "self").imagesSet.item.each do |image|
     	 str = image.imageId
     	 str << " ("
     	 str << image.imageLocation
     	 str << ") status: ("
     	 str << 
     	 str << image.imageState
     	 str << " and "
     	 p = (image.isPublic == "true")? "public" : "private"
     	 str << p
     	 str << ")"
     	 puts str
    end
  end
  
  set(:ami) do
    Capistrano::CLI.ui.ask "What is the image ami you would like to launch? (use ami-08806561 as default)"
  end
  
  desc <<-DESC
  Run an image. You must first get the ami id by running cap ec2:images.
  Example - cap -s image=ami-08806561 launch_instance
  DESC
  task :launch_instance do
    setup_keyname
    reservation = @aws.connect.run_instances(:image_id => ami, :key_name=>@aws.key[:name])
    reservation.instancesSet.item.each do |item|
      raise Exception, "Instance did not start." unless item.instanceState.name == "pending"
      puts "Instance #{item.instanceId} Startup Pending" 
       #loop checking for instance startup
       puts "Checking every 10 seconds to detect startup for up to 5 minutes"
       tries = 0
         while tries < 35
           launched = @aws.connect.describe_instances(:instance_id =>[item.instanceId]).reservationSet.item.first.instancesSet.item.first
           case launched.instanceState.name
             when "pending"
               puts launched.instanceState.name
               sleep 10
               tries += 1
             when "running"
               puts "running " + launched.dnsName
               break
             else
               puts "error initializing instance: #{item.instanceId}"
               break
           end
         end
      end
  end
  
  set(:terminate_id) do
    Capistrano::CLI.ui.ask "What is the instance id you would like to terminate? "
  end
  
  set(:instance_id) do
    Capistrano::CLI.ui.ask "What is the instance id you would like to check? "
  end
  
  desc <<-DESC 
  Terminate an instance. You must first get the id by running cap ec2:instances.
  Example - rake -s id=i-5f826536 ec2:terminate 
  DESC
  task :terminate do
      instance = @aws.connect.terminate_instances(:instance_id => [terminate_id]).instancesSet.item.first
      puts instance.instanceId + " " + instance.shutdownState.name
  end
  
  task :instance do
    puts @aws.connect.describe_instances(:instance_id =>[instance_id]).reservationSet.item.first.instancesSet.item.first.dnsName
  end
  
  desc <<-DESC
  Returns all of your currently running instances
  DESC
  task :instances do
    @aws.connect.describe_instances.reservationSet.item.each do |set|
      set.instancesSet.item.each do |instance|
       str = instance.instanceId
       str << " ("
       str << instance.instanceState.name
       if instance.instanceState.name == "running"
         str << " at "
         str << instance.dnsName
         str << " on image "
         str << instance.imageId
       end
       str << ")"
       puts str
      end
    end
  end
  
  desc <<-DESC
  Create the key pair if it has not already been created.
  DESC
  task :setup_keyname do
    keyname = @aws.key[:name]
    if keypair_needed?
     create_keypair
    else
      puts @aws.connect.describe_keypairs(:key_name => [@aws.key[:name]]).keySet
    end
  end
  
  task :keypair_needed? do
    @aws.connect.describe_keypairs(:key_name => [@aws.key[:name]]).keySet.nil?
  end
  
  task :create_keypair do
    keyname = @aws.key[:name]
    keypath = @aws.key[:path]
    key = @aws.connect.create_keypair(:key_name => keyname)
    puts key.keyName
    #TODO: exception handling
    
    begin
      unless keypath == nil
        #write private key to file
        File.open(keypath + "id_rsa-"+keyname, "wb+") { |f| f.write(key.keyMaterial) }
        system "chmod 600 #{keypath + "id_rsa-" + keyname}"
        puts "Written to #{keypath}"
      end
    rescue
      delete_keypair
      puts "Error in writing the keypair"
    end
  end
  
  desc <<-DESC
  Copy the keys up to the server
  DESC
  def copy_keys
    run "scp -i #{@aws.key[:path]}id_rsa-#{@aws.key[:name]} #{ENV['EC2_PRIVATE_KEY']} #{ENV['EC2_CERT']} root@#{@aws.access[:url]}:/tmp"
  end
  
  task :delete_keypair do
    keyname = @aws.key[:name]
    @aws.connect.delete_keypair(:key_name => keyname)
    #TODO: exception handling
  end
  
  on :before, "ec2:aws", :except => "ec2:aws"
end

class Aws
require 'ec2'

  def initialize
    @access_key   = 'YOUR-AWS-ACCESS-KEY'
    @secret_key   = 'YOUR-AWS-SECRET-KEY'
    @account      = 'YOUR-AWS-ACCOUNT-NUMBER'
    @key_path     = 'WHERE-YOU-WANT-YOUR-KEY-STORED-LOCALLY'
    @keyname = 'YOUR-KEYNAME-CAN-BE-ANYTHING'
    
    @url = 'YOUR-EC2-URL-AFTER-CREATING-AN-INSTNACE'

    #s3 Related
    @image_bucket = "THE-NAME-OF-THE-STORAGE-BUCKET-AT-S2"
    
  end
  
  def access
    { :key => @access_key, :secret => @secret_key, :account => @account, :url => @url }
  end
  
  def key
    { :name => @keyname, :path => @key_path }
  end
  
  def connect
    amazon = EC2::Base.new(:access_key_id => @access_key, :secret_access_key => @secret_key)
    raise Exception, "Connection to AWS failed. Check your Access Key ID and Secret Access Key - http://aws.amazon.com/" if amazon.nil?
    return amazon
  end

  # The timestamp is used when bun
  def get_timestamp
    Time.now.utc.strftime("%b%d%Y")
  end  
end
