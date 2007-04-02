# ----------------------------------------------------------
# EC2 related tasks
# ----------------------------------------------------------

  # Describe the available images to launch. To get public images to add id=amazon to your request.
  # Example: rake ec2:images id=844412190991
  def images
    p ||= (ENV['id'])? ENV['id'] : 'self'
    puts connect.describe_images([],["#{p}"],[])
  end
  
  #Run an image. You must first get the ami id by running 'rake ec2:images.'
  #Example - cap run -s image=ami-61a54008
  def launch_instance(image)
    setup_keypair unless keypair_exists?(aws('keypair_name'))
    instance = connect.run_instances(image, :keyname=>aws('keypair_name')).parse[1]
    puts instance[0]
    raise Exception, "Instance did not start" unless instance[4] == "pending"
    instance_id = instance[1]
    puts "Instance #{instance_id} Startup Pending"
  
    #loop checking for instance startup
    puts "Checking every 10 seconds to detect startup for up to 5 minutes"
    tries = 0
      while tries < 35
        instance_desc = connect.describe_instances.parse.select { |i| i[1] == instance_id.to_s }[0]
        case instance_desc[4]
          when "pending"
            puts instance_desc[4]
            sleep 10
            tries += 1
          when "running"
            puts "running " + instance_desc[3]
            return
          else
            puts "error initializing instance: #{instance_desc[4]}"
            return
        end
      end
     puts "error initalizing instance"
  end
  
  # Describe instances that are currently running
  def instances
    puts connect.describe_instances
  end
  
  # Copy Keys to EC2 Server
  def copy_keys
    bash "scp -i #{aws('key_path')}id_rsa-#{aws('keypair_name')} #{ENV['EC2_PRIVATE_KEY']} #{ENV['EC2_CERT']} root@#{aws('url')}:/tmp"
  end
  
  # Delete keypair
  def delete_keypair(keypair)
    connect.delete_keypair(keypair)
  end
  
  def keypair_exists?(keypair)
    connect.describe_keypairs.parse.each { |k| return true if k[1] == keypair}
    false
  end
  
  # Create a keypair
  def setup_keypair
    keypair_name = aws('keypair_name')
    private_key_path = aws('key_path')
    puts connect.describe_keypairs
    
    #create a new key if one doesn't exist
    if connect.describe_keypairs(keypair_name).parse.empty?
    
      #create keypair
      private_key = connect.create_keypair(keypair_name)
      raise Exception, "Private Key not correctly generated" unless private_key.parse[0][0] == "KEYPAIR"
      puts "Keypair \"#{keypair_name}\" generated"
    
      begin
        unless private_key_path == nil
          #write private key to file
          text_private_key = private_key.parse.inject("") { |text_private_key, a| a.join("\t") + "\n" }
          File.open(private_key_path + "id_rsa-"+keypair_name, "wb+") { |f| f.write(text_private_key) }
          system "chmod 600 #{private_key_path + "id_rsa-" + keypair_name}"
          puts "Written to ./#{private_key_path}"
        end
      rescue
        connect.delete_keypair(keypair_name)
        puts "Error in writing the keypair"
      end

    end
  end
  
  # Bundle our ec2 instance
  def bundle_instance 
    sudo "ec2-bundle-vol -k /tmp/pk-*.pem -u #{aws('account')} -s 1536 -d /mnt -c /tmp/cert-*.pem -p #{get_timestamp}"
  end

  # Upload our remote ec2 image to s3
  def upload_image
    sudo "ec2-upload-bundle -b #{aws('image_bucket')} -m /mnt/#{get_timestamp}.manifest.xml -a #{aws('access_key')} -s #{aws('secret_key')}"
  end
  
  # Register the image at ec2"
  def register
    connect.register_image(aws('image_bucket')+ "/#{get_timestamp}.manifest.xml")
  end
  
  # Bundle and upload the image to s3"
  def complete_bundle
    bundle_instance
    upload_image
    register
    puts "Enjoy your new instance"
  end
  
  # Terminate an instance. You must first get the id by running 'rake ec2:instances.'
  # Example - rake ec2:terminate id=i-5f826536
  def terminate(instance_id)
      puts connect.terminate_instances(instance_id)
  end
  
  # Login to our EC2 instance. You can pass in the username with id=username
  # Example - rake ec2:login id=steveodom
  def login(usr = 'root') 
    #usr = (ENV['id'])? ENV['id'] : 'root'
    bash "ssh -i #{aws('key_path')+"id_rsa-" + aws('keypair_name')} #{usr}@#{aws('url')}"
  end
  
  # Install Amazon AWS Tools to bundle and upload if needed ALREADY INSTALLED ON IMAGE
  def install_amazon_tools
    #Amazon AWS tools
    run <<-CMD
      wget http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm && 
      rpm -i ec2-ami-tools.noarch.rpm &&
      rm ec2-ami-tools.noarch.rpm
    CMD
  end

  private
  
  def connect
    amazon = EC2::AWSAuthConnection.new(aws('access_key'), aws('secret_key'))
    raise Exception, "Connection to AWS failed. Check your Access Key ID and Secret Access Key - http://aws.amazon.com/" if amazon.nil?
    return amazon
  end
  
  def bash(cmd)
    puts(cmd) 
    system(cmd)
  end
  
  # The timestamp is used when bun
  def get_timestamp
    Time.now.utc.strftime("%b%d%Y")
  end
  
  
  
