#!/bin/bash
#
# make Wordpress instance
#
# parameters for this WP instance
OWNER="adminusername"       # owner for wordpress instance
GROUP="staff"               # group for wordpress instance
SITESROOT="/base/var/www"   # where websites are located
URL="www.test.com"          # URL for 
SITEDIR=$URL                # directory name inside $SITESROOT
DESTINATION_DIR="public"    # directory unser $SITEDIR where WP files will be located

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
	echo "$SITESROOT directory does not exist"
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
sudo chown $OWNER:www-data logs
chmod g+ws logs
touch logs/error.log
touch logs/combined.log
 
# create Apache virtual site
echo creating Apache virtual site file in /etc/apache2/sites-available
echo "<VirtualHost *:80>
	ServerName $URL
	DocumentRoot $SITESROOT/$SITEDIR/$DESTINATION_DIR
	DirectoryIndex index.php
	LogLevel warn
	ErrorLog $SITESROOT/$SITEDIR/logs/error.log
	CustomLog $SITESROOT/$SITEDIR/logs/combined.log combined
</VirtualHost>
" > /etc/apache2/sites-available/$SITEDIR

# finish up with instructions to admin
echo -e "To finish, do the following:\n"
echo "1. Enable site with: sudo a2ensite $SITEDIR"
echo "2. Restart Apache with: service apache2 reload"
echo -e "3. Create a MySQL database with:\n"
echo -e "\t     user: $DBUSER"
echo -e "\t      pwd: $DBPWD"
echo -e "\t     host: $DBHOST"
echo -e "\t database: $DBNAME"
echo -e "\nVia the command line:"
echo -e 'mysql --user=root --password=ROOTPASSWORDHERE -e "CREATE USER '$DBUSER'@'$DBHOST';"'
echo -e 'mysql --user=root --password=ROOTPASSWORDHERE -e "CREATE DATABASE '$DBNAME';"'
echo -e 'mysql --user=root --password=ROOTPASSWORDHERE -e "GRANT ALL PRIVILEGES ON '$DBNAME' . * TO '$DBUSER'@'$DBHOST';"'

echo -e "mysql --user=root --password=ROOTPASSWORDHERE -e \"SET PASSWORD FOR  '$DBUSER'@'$DBHOST' = PASSWORD( '$DBPWD' );\""

echo "4. Open http://$URL/wp-admin/install.php and finish the set-up."