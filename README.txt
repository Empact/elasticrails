How to install
1. install the plugin
ruby script/plugin install svn://rubyforge.org/var/svn/elasticrails

2. Install capistrano
<pre>gem install -y capistrano</pre>

3. "Capify" your app
<pre>capify .</pre>
..from the root directory of your rails application

4. Add the following to the Capfile that is generated:

load 'vendor/plugins/elasticrails/elastic_rails'

..and comment out the second line like this:
#load 'config/deploy'