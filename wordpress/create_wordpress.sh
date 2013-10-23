#!/bin/bash
#
# create_wordpress.sh
#
# Script's documentation page: http://www.adminbuntu.com/create_wordpress_instance
#
# Create a Wordpress instance on an Ubuntu Server. Customize the parameters near the tops of this
# script for your server and the WordPress site that you wish to create.
#
# Copyright 2013 Andrew Ault
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#
# parameters for this WP instance
OWNER="adminusername"       # owner for wordpress instance
GROUP="staff"               # group for wordpress instance
SITESROOT="/base/var/www"   # where websites are located
URL="www.test.com"          # URL for 
SITEDIR=$URL                # directory name inside $SITESROOT
DESTINATION_DIR="public"    # directory under $SITEDIR where WP files will be located

# database.php parameters
DBNAME="test"               # database for this WP instance
DBUSER=$DBNAME              # user that WP will use to access database
DBPWD=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 20 | xargs`  # auto generate a strong PW
DBHOST="localhost"          # mysql server 

# where to download WP from
WORDPRESS_URL="http://wordpress.org/latest.tar.gz"
 
# make sure this is run as root
if [[ $UID -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

if [ ! -d $SITESROOT ]; then
    echo "$SITESROOT SITESROOT directory does not exist"
    exit
fi
 
# change to the siteroot directory
cd $SITESROOT
 
if [ -d $SITEDIR ]; then
    echo "$SITESROOT/$SITEDIR directory already exists"
    exit
fi 
 
mkdir $SITEDIR
chown $OWNER:$GROUP $SITEDIR
cd $SITEDIR
 
# check for existence of the specified user owner
/bin/egrep  -i "^$USER" /etc/passwd > /dev/null
if [ ! $? -eq 0 ]; then
    echo "User $USER, which is specified as the owner, does not exist in /etc/passwd"
    exit
fi
 
# check for existence of the specified group
/bin/egrep -i "^$GROUP" /etc/group > /dev/null
if [ ! $? -eq 0 ]; then
    echo "User $GROUPNAME, which is specified as the group to use, does not exist in /etc/group"
    exit
fi

# get Wordpress
echo 'get Wordpress'
wget -O wordpress.tgz $WORDPRESS_URL
tar -xzvf wordpress.tgz
rm wordpress.tgz
mv wordpress $DESTINATION_DIR
sudo chown -R $OWNER:$GROUP $DESTINATION_DIR
find . -type d -exec chmod g+ws {} \;
find . -type f -exec chmod g+w {} \;
cp $DESTINATION_DIR/wp-config-sample.php $DESTINATION_DIR/wp-config.php
 
sed -i "s/'database_name_here'/'$DBNAME'/" $DESTINATION_DIR/wp-config.php
sed -i "s/'username_here'/'$DBUSER'/" $DESTINATION_DIR/wp-config.php
sed -i "s/'password_here'/'$DBPWD'/" $DESTINATION_DIR/wp-config.php
sed -i "s/'localhost'/'$DBHOST'/" $DESTINATION_DIR/wp-config.php
 
PASSPHRASE=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 | xargs`
sed -i "s/define('AUTH_KEY',[ \t\t]*'put your unique phrase here');/define('AUTH_KEY',\t'$PASSPHRASE');/" $DESTINATION_DIR/wp-config.php
PASSPHRASE=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 | xargs`
sed -i "s/define('SECURE_AUTH_KEY',[ \t]*'put your unique phrase here');/define('SECURE_AUTH_KEY',\t'$PASSPHRASE');/" $DESTINATION_DIR/wp-config.php
PASSPHRASE=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 | xargs`
sed -i "s/define('LOGGED_IN_KEY',[ \t\t]*'put your unique phrase here');/define('LOGGED_IN_KEY',\t'$PASSPHRASE');/" $DESTINATION_DIR/wp-config.php
PASSPHRASE=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 | xargs`
sed -i "s/define('NONCE_KEY',[ \t\t]*'put your unique phrase here');/define('NONCE_KEY',\t'$PASSPHRASE');/" $DESTINATION_DIR/wp-config.php
PASSPHRASE=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 | xargs`
sed -i "s/define('AUTH_SALT',[ \t\t]*'put your unique phrase here');/define('AUTH_SALT',\t'$PASSPHRASE');/" $DESTINATION_DIR/wp-config.php
PASSPHRASE=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 | xargs`
sed -i "s/define('SECURE_AUTH_SALT',[ \t]*'put your unique phrase here');/define('SECURE_AUTH_SALT',\t'$PASSPHRASE');/" $DESTINATION_DIR/wp-config.php
PASSPHRASE=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 | xargs`
sed -i "s/define('LOGGED_IN_SALT',[ \t]*'put your unique phrase here');/define('LOGGED_IN_SALT',\t'$PASSPHRASE');/" $DESTINATION_DIR/wp-config.php
PASSPHRASE=`exec tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 | xargs`
sed -i "s/define('NONCE_SALT',[ \t\t]*'put your unique phrase here');/define('NONCE_SALT',\t'$PASSPHRASE');/" $DESTINATION_DIR/wp-config.php
 

# logs
echo "set up logs"
mkdir logs
chown $OWNER:www-data logs
chmod g+ws logs
touch logs/error.log
touch logs/combined.log
 
# create Apache virtual site
echo creating Apache virtual site file in /etc/apache2/sites-available
echo -e "<VirtualHost *:80>
\tServerName $URL
\tDocumentRoot $SITESROOT/$SITEDIR/$DESTINATION_DIR
\tDirectoryIndex index.php
\tLogLevel warn
\tErrorLog $SITESROOT/$SITEDIR/logs/error.log
\tCustomLog $SITESROOT/$SITEDIR/logs/combined.log combined
</VirtualHost>
" > /etc/apache2/sites-available/$SITEDIR
chown $OWNER:$OWNER /etc/apache2/sites-available/$SITEDIR

# finish up with instructions to admin
echo -e "To finish, do the following:\n"
echo "1. Enable site with: sudo a2ensite $SITEDIR"
echo "2. Test Apache2 configuration: sudo /usr/sbin/apache2ctl configtest"
echo "3. Restart Apache with: service apache2 reload"
echo -e "4. Create a MySQL database with:\n"
echo -e "\t     user: $DBUSER"
echo -e "\t      pwd: $DBPWD"
echo -e "\t     host: $DBHOST"
echo -e "\t database: $DBNAME"
echo -e "\nVia the command line:"
echo -e 'mysql --user=root --password=ROOTPASSWORDHERE -e "CREATE USER '$DBUSER'@'$DBHOST';"'
echo -e 'mysql --user=root --password=ROOTPASSWORDHERE -e "CREATE DATABASE '$DBNAME';"'
echo -e 'mysql --user=root --password=ROOTPASSWORDHERE -e "GRANT ALL PRIVILEGES ON '$DBNAME' . * TO '$DBUSER'@'$DBHOST';"'
echo -e "mysql --user=root --password=ROOTPASSWORDHERE -e \"SET PASSWORD FOR  '$DBUSER'@'$DBHOST' = PASSWORD( '$DBPWD' );\""

echo "5. Open http://$URL/wp-admin/install.php and finish the set-up."