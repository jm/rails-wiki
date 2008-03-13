require 'rubygems'
require 'deprec/recipes'

default_run_options[:pty] = true
set :application, "rails-wiki"
set :scm, :git
set :scm_passphrase, "pilgrim"
set :repository,  "git@github.com:jeremymcanally/rails-wiki.git"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "deploy@67.207.142.186"
role :web, "deploy@67.207.142.186"
role :db,  "deploy@67.207.142.186", :primary => true

# my custom stack install, including all necessary packages for rails, mysql, and nginx
 
task :install_rails_stack_with_nginx do
  setup_user_perms
  enable_universe # we'll need some packages from the 'universe' repository
  disable_cdrom_install # we don't want to have to insert cdrom
  install_packages_for_rails # install packages that come with distribution
  install_rubygems
  install_gems
  install_nginx
end
 
task :setup_firewall do
  sudo 'echo \'#!/bin/bash\' >> /tmp/firewall.sh'
  sudo 'echo \'sudo iptables -A INPUT -j ACCEPT -p tcp --destination-port 80 -i eth0\' >> /tmp/firewall.sh'
  sudo 'echo \'sudo iptables -A INPUT -j ACCEPT -p tcp --destination-port 443 -i eth0\' >> /tmp/firewall.sh'
  sudo 'echo \'sudo iptables -A INPUT -j ACCEPT -p tcp --destination-port 22 -i eth0\' >> /tmp/firewall.sh'
  sudo 'echo \'sudo iptables -A INPUT -j DROP -p tcp -i eth0\' >> /tmp/firewall.sh'
  sudo 'chown root:root /tmp/firewall.sh'
  sudo 'chmod +x /tmp/firewall.sh'
  sudo 'mv /tmp/firewall.sh /etc/init.d/'
  sudo '/etc/init.d/firewall.sh'
  sudo 'update-rc.d firewall.sh defaults'
end
 
# nginx recipes
 
task :install_nginx do
  install_pcre
  version = 'nginx-0.5.35'
  set :src_package, {
    :file => version + '.tar.gz',    
    :dir => version,  
    :url => "http://sysoev.ru/nginx/#{version}.tar.gz",
    :unpack => "tar -xzvf #{version}.tar.gz;",
    :configure => './configure --sbin-path=/usr/local/sbin --with-http_ssl_module;',
    :make => 'make;',
    :install => 'make install;',
  }
  deprec.download_src(src_package, src_dir)
  deprec.install_from_src(src_package, src_dir)
  sudo 'wget http://notrocketsurgery.com/files/nginx -O /etc/init.d/nginx'
  sudo 'chmod 755 /etc/init.d/nginx'
  send(run_method, "update-rc.d nginx defaults")
end
 
task :configure_nginx do
  stop_nginx
  sudo "cp #{release_path}/config/nginx.conf /usr/local/nginx/conf/"
  start_nginx
end
 
task :install_pcre do
  apt.install({:base => ['libpcre3', 'libpcre3-dev']}, :stable)
end
 
task :start_nginx do
  sudo '/etc/init.d/nginx start'
end
 
task :restart_nginx do
  sudo '/etc/init.d/nginx restart'
end
 
task :stop_nginx do
  sudo '/etc/init.d/nginx stop'
end
 
task :create_database_yml do
  run "cp #{release_path}/config/database.yml.production #{release_path}/config/database.yml"  
end
 
# here is my section to tie this all together and make it as easy as three cap instructions to setup a new server
task :deploy_first_time do
  setup
  deploy
  create_database_yml
  setup_mysql
  migrate
  configure_mongrel_cluster
  configure_nginx
  restart_mongrel_cluster
  start_nginx
end
 
# overwrite the deprec read_config task so that it grabs the right config
def read_config
  db_config = YAML.load_file('config/database.yml.production')
  set :db_user, db_config[rails_env]["username"]
  set :db_password, db_config[rails_env]["password"] 
  set :db_name, db_config[rails_env]["database"]
end