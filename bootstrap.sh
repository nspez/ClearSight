#!/usr/bin/env bash
 	#sudo add-apt-repository ppa:chris-lea/node.js 
	 sudo apt-get update
	 sudo apt-get install -y yum
	 sudo apt-get install -y yum-utils
 	 sudo apt-get install -y apache2 
	 sudo apt-get install -y openssl
    
     #sudo npm install -g grunt-cli. # grunt is already installed in this release
     # if /var/www is not a symlink then create the symlink and set up apache
	 # Configure 
	 if [ ! -h /var/www ];
	 then
	    rm -rf /var/www
	    ln -fs /vagrant/httpdocs /var/www
	    sudo a2enmod rewrite 
	    sed -i '/AllowOverride None/c AllowOverride All' /etc/apache2/sites-available/000-default.conf
	    sed -i '/AllowOverride None/c AllowOverride All' /etc/apache2/sites-available/default-ssl.conf
	    sudo service apache2 restart 
	 fi

	# restart apache
	sudo service apache2 restart
	
	sudo apt-get install -y make 

	sudo a2enmod rewrite 
	APACHEUSR=`grep -c 'APACHE_RUN_USER=www-data' /etc/apache2/envvars`
	APACHEGRP=`grep -c 'APACHE_RUN_GROUP=www-data' /etc/apache2/envvars`
	if [ APACHEUSR ]; then
    	sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/' /etc/apache2/envvars
	fi
	if [ APACHEGRP ]; then
    	sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/' /etc/apache2/envvars
	fi
	sudo chown -R vagrant:www-data /var/lock/apache2

	sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password ROOTPASSWORD'
	sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password ROOTPASSWORD'
	sudo apt-get install -y mysql-server 
	sudo apt-get install -y mysql-client 

	if [ ! -f /var/log/dbinstalled ];
	then
    	echo "CREATE USER 'mysqluser'@'localhost' IDENTIFIED BY 'USERPASSWORD'" | mysql -uroot -pROOTPASSWORD
    	echo "CREATE DATABASE internal" | mysql -uroot -pROOTPASSWORD
    	echo "GRANT ALL ON internal.* TO 'mysqluser'@'localhost'" | mysql -uroot -pROOTPASSWORD
    	echo "flush privileges" | mysql -uroot -pROOTPASSWORD
    	touch /var/log/dbinstalled
    	if [ -f /vagrant/data/initial.sql ];
    	then
        	mysql -uroot -pROOTPASSWORD internal < /vagrant/data/initial.sql
    	fi
	fi

	sudo apt-get install -y memcached libmemcached-tools

	sudo apt-get install -y php5 
	sudo apt-get install -y php-pear 
	sudo apt-get install -y php5-dev 
	sudo apt-get install -y php5-gd 
	sudo apt-get install -y php5-curl 
	sudo apt-get install -y php5-mcrypt 
	sudo apt-get install -y php5-mysql
	sudo apt-get install -y libapache2-mod-php5
	sudo apt-get install -y php-auth
	sudo apt-get install -y php-auth-http
 	sudo apt-get install -y php5-fpm 
 	sudo apt-get install -y php5-suhosin 
 	sudo apt-get install -y php-apc 
 	sudo apt-get install -y php5-curl
   	sudo pecl install memcache 
	sudo aptitude install memcached php5-memcache
	
	sudo touch /etc/php5/conf.d/memcache.ini
	sudo echo "extension=memcache.so" >> /etc/php5/conf.d/memcache.ini
	sudo echo "memcache.hash_strategy=\"consistent\"" >> /etc/php5/conf.d/memcache.ini

	# if /var/www is not a symlink then create the symlink and set up apache
	if [ ! -h /var/www ];
	then
    	rm -rf /var/www
    	ln -fs /vagrant/httpdocs /var/www
    	sudo a2enmod rewrite 
    	sed -i '/AllowOverride None/c AllowOverride All' /etc/apache2/sites-available/default
    	sudo service apache2 restart 
	fi

	# restart apache
	sudo service apache2 reload 

	# copy addwebsite command
	#cp /vagrant/addwebsite /usr/local/bin/addwebsite 
	#chmod +x /usr/local/bin/addwebsite
	#cp /vagrant/skeleton /etc/apache2/sites-available/skeleton 

	sudo apt-get install -y git 

	# install phpmyadmin
	mkdir /vagrant/phpmyadmin/ 
	wget -O /vagrant/phpmyadmin/index.html http://www.phpmyadmin.net/
	awk 'BEGIN{ RS="<a *href *= *\""} NR>2 {sub(/".*/,"");print; }' /vvagrant/phpmyadmin/index.html >> /vagrant/phpmyadmin/url-list.txt
	grep "http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/" /vagrant/phpmyadmin/url-list.txt > /vagrant/phpmyadmin/phpmyadmin.url
	sed -i 's/.zip/.tar.bz2/' /vagrant/phpmyadmin/phpmyadmin.url
	wget -O /vagrant/phpmyadmin/phpMyAdmin.tar.bz2 `cat /vagrant/phpmyadmin/phpmyadmin.url`
	mkdir /vagrant/myadm.localhost
	tar jxvf /vagrant/phpmyadmin/phpMyAdmin.tar.bz2 -C /vagrant/myadm.localhost --strip 1
	rm -rf /vagrant/phpmyadmin

	# configure phpmyadmin
	mv /vagrant/myadm.localhost/config.sample.inc.php /vagrant/myadm.localhost/config.inc.php
	sed -i 's/a8b7c6d/NEWBLOWFISHSECRET/' /vagrant/myadm.localhost/config.inc.php
	echo "CREATE DATABASE pma" | mysql -uroot -pROOTPASSWORD
	echo "CREATE USER 'pma'@'localhost' IDENTIFIED BY 'PMAUSERPASSWD'" | mysql -uroot -pROOTPASSWORD
	echo "GRANT ALL ON pma.* TO 'pma'@'localhost'" | mysql -uroot -pROOTPASSWORD
	echo "GRANT ALL ON phpmyadmin.* TO 'pma'@'localhost'" | mysql -uroot -pROOTPASSWORD
	echo "flush privileges" | mysql -uroot -pROOTPASSWORD
	mysql -D pma -u pma -pPMAUSERPASSWD < /vagrant/myadm.localhost/examples/create_tables.sql
	cat /vagrant/phpmyadmin.conf > /vagrant/myadm.localhost/config.inc.php
	
	# set up mywebsite.localhost
	if [ ! -d /vagrant/mywebsite.localhost ];
	then
	    git clone ssh://git@domain.com/repo/mywebsite.com /vagrant/mywebsite.localhost 2> /dev/null
	    cp /vagrant/skeleton /etc/apache2/sites-available/mywebsite.localhost 2> /dev/null
	    find /etc/apache2/sites-available/mywebsite.localhost -type f -exec sed -i "s/SKELETON/mywebsite.localhost/" {} \;
	fi
	if [ ! -d /var/lib/mysql/mywebsite ];
	then
	    echo "CREATE USER 'mysqluser'@'localhost' IDENTIFIED BY 'USERPASSWORD'" | mysql -uroot -pROOTPASSWORD
	    echo "CREATE DATABASE mywebsite" | mysql -uroot -pROOTPASSWORD
	    echo "GRANT ALL ON mywebsite.* TO 'mysqluser'@'localhost'" | mysql -uroot -pROOTPASSWORD
	    echo "flush privileges" | mysql -uroot -pROOTPASSWORD
	    if [ -f /vagrant/mywebsite.sql ];
	    then
	        mysql -uroot -pROOTPASSWORD mywebsite < /vagrant/mywebsite.sql 2> /dev/null
	    fi
	fi
    sudo apt-get install -y libjs-jquery
    #sudo apt-get install -y twitter-bootstrap
    sudo apt-get install -y libjs-twitter-bootstrap 
    sudo apt-get install -y libjs-twitter-bootstrap-docs
    sudo apt-get install -y node.js
    sudo apt-get install -y npm
    sudo ln -s /usr/bin/nodejs /usr/bin/node # need to establish link
	#sudo ln -s /usr/share/twitter-bootstrap/files/ distln -s /usr/share/twitter-bootstrap/files/ /var/dist
	sudo ln -s /etc/apache2/conf-available/libjs-twitter-bootstrap.conf /etc/apache2/conf-enabled/
	
	#php.ini modifications /etc/php5/conf.d/
	#sed -i 's/session.save_handler/session.save_handler = memcache/' /etc/php5/apache2/php.ini
	#sed -i 's/session.save_path /session.save_path = unix:/tmp/memcached.sock/' /etc/php5/apache2/php.ini
	#session.save_handler = memcache
	#session.save_path = unix:/tmp/memcached.sock
	
	# add includes into apache
	sudo ln -s /etc/apache2/mods-available/include.load /etc/apache2/mods-enabled
	sudo ln -s /etc/apache2/mods-available/session.load /etc/apache2/mods-enabled
 	sudo ln -s /etc/apache2/mods-available/session_crypto.load /etc/apache2/mods-enabled
 	sudo ln -s /etc/apache2/mods-available/session_cookie.load /etc/apache2/mods-enabled
 	sudo ln -s /etc/apache2/mods-available/session_dbd.load /etc/apache2/mods-enabled
 	
 	# need to fix server side includes need to modify the 000-default configuration file
 	# /etc/apache2/sites-available/000-default.conf
 	 
 	sudo sed -i '/<Directory \/>/a\     Options Includes' /etc/apache2/apache2.conf
 	echo "AddType text/html .shtml" > /etc/apache2/mods-enabled/include.conf
 	echo "AddOutputFilter INCLUDES .shtml" >> /etc/apache2/mods-enabled/include.conf
 	echo "AddOutputFilter INCLUDES .html"	>> /etc/apache2/mods-enabled/include.conf
 	
 	echo " <VirtualHost *:80>" > /etc/apache2/sites-available/000-default.conf
 	echo "        # The ServerName directive sets the request scheme, hostname and port that " >> /etc/apache2/sites-available/000-default.conf
  	echo "       # the server uses to identify itself. This is used when creating " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # redirection URLs. In the context of virtual hosts, the ServerName " >> /etc/apache2/sites-available/000-default.conf
  	echo "       # specifies what hostname must appear in the request's Host: header to " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # match this virtual host. For the default virtual host (this file) this " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # value is not decisive as it is used as a last resort host regardless. " >> /etc/apache2/sites-available/000-default.conf
  	echo "       # However, you must set it for any further virtual host explicitly. " >> /etc/apache2/sites-available/000-default.conf
  	echo "       #ServerName www.example.com " >> /etc/apache2/sites-available/000-default.conf
 	echo " " >> /etc/apache2/sites-available/000-default.conf
  	echo "       ServerAdmin webmaster@localhost " >> /etc/apache2/sites-available/000-default.conf
  	echo "       DocumentRoot /var/www/html " >> /etc/apache2/sites-available/000-default.conf
 	echo " " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn, " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # error, crit, alert, emerg. " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # It is also possible to configure the loglevel for particular " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # modules, e.g. " >> /etc/apache2/sites-available/000-default.conf
 	echo "        #LogLevel info ssl:warn " >> /etc/apache2/sites-available/000-default.conf
 	echo " " >> /etc/apache2/sites-available/000-default.conf
 	echo "        ErrorLog ${APACHE_LOG_DIR}/error.log " >> /etc/apache2/sites-available/000-default.conf
 	echo "        CustomLog ${APACHE_LOG_DIR}/access.log combined " >> /etc/apache2/sites-available/000-default.conf
 	echo " " >> /etc/apache2/sites-available/000-default.conf
  	echo "        # For most configuration files from conf-available/, which are " >> /etc/apache2/sites-available/000-default.conf
   	echo "        # enabled or disabled at a global level, it is possible to " >> /etc/apache2/sites-available/000-default.conf
    echo "        # include a line for only one particular virtual host. For example the " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # following line enables the CGI configuration for this host only " >> /etc/apache2/sites-available/000-default.conf
 	echo "        # after it has been globally disabled with a2disconf. " >> /etc/apache2/sites-available/000-default.conf
  	echo "        #Include conf-available/serve-cgi-bin.conf " >> /etc/apache2/sites-available/000-default.conf
  	echo "       <Directory /var/www/> " >> /etc/apache2/sites-available/000-default.conf
 	echo "                Options FollowSymlinks Includes " >> /etc/apache2/sites-available/000-default.conf
 	echo "                AllowOverride None " >> /etc/apache2/sites-available/000-default.conf
 	echo "                Order allow,deny " >> /etc/apache2/sites-available/000-default.conf
 	echo "                Allow from All " >> /etc/apache2/sites-available/000-default.conf
 	echo "        </directory> " >> /etc/apache2/sites-available/000-default.conf
 	echo "</VirtualHost> " >> /etc/apache2/sites-available/000-default.conf


 	
 	# restart apache
	sudo service apache2 reload 
 	echo "Clearview server configuration completed"
 	