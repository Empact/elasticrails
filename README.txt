How to install

1. Install capistrano
<pre>gem install -y capistrano</pre>
2. "Capify" your app
<pre>capify .</pre>
..from the root directory of your rails application
3. Add the following to the Capfile that is generated:

load 'vendor/plugins/elasticrails/elastic_rails'

..and comment out the second line like this:
#load 'config/deploy'