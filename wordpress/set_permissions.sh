#!/bin/bash
#
# set_permissions.sh
#
# change WordPress owner and permissions
#
# Script's documentation page: http://www.adminbuntu.com/wordpress_permissions
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
 
INSTALL_DIR="/base/var/www/www.websitename.com/public"  # where is WP installed
USER="usernamehere"                                               # user that owns this installation, like "steve"
GROUP="staff"                                               # group for this installation, like "staff"
APACHE_USER="www-data"                                      # apache2's user like "www-data"
APACHE_GROUP="www-data"                                     # apache2's group like "www-data"
URL="www.websitename.com"
 
#
# make sure this is run as root
#
echo '**** make sure this is run as root ****'
if [[ $UID -ne 0 ]]; then
    echo "Not running as root"
    exit
fi
 
#
# Check for existence of the specified user owner
# Stop is the owner does not exist
#
echo '**** Check for existence of the specified user owner ****'
/bin/egrep  -i "^$USER" /etc/passwd > /dev/null
if [ ! $? -eq 0 ]; then
   echo "User $USER, which is specified as the owner, does not exist in /etc/passwd"
   exit
fi
 
#
# Check for existence of the specified group
# Stop is the group does not exist
#
echo '**** Check for existence of the specified group ****'
/bin/egrep -i "^$GROUP" /etc/group > /dev/null
if [ ! $? -eq 0 ]; then
   echo "User $GROUPNAME, which is specified as the group to use, does not exist in /etc/group"
   exit
fi
 
#
# Check whether the installation directory already exists
# Stop if it does not exist.
#
#
echo '**** Check whether the installation directory already exists ****'
if [ ! -d $INSTALL_DIR ]; then
	echo "$INSTALL_DIR directory does not exist"
	exit
fi
 
#
# Change ownership and permissions
#
#
echo '**** Set permissions ****'
cd $INSTALL_DIR
cd ..
chown $USER:$GROUP $INSTALL_DIR
cd $INSTALL_DIR
chown -R $USER:$GROUP $INSTALL_DIR
chown www-data:www-data wp-config.php
 
if [ ! -d $INSTALL_DIR/wp-content/uploads ]; then
	mkdir $INSTALL_DIR/wp-content/uploads
fi
 
find $INSTALL_DIR -exec chown $USER:$GROUP {} \;
find $INSTALL_DIR -type d -exec chmod 755 {} \;
find $INSTALL_DIR -type f -exec chmod 644 {} \;
find $INSTALL_DIR -type d -exec chmod g+ws {} \;
find $INSTALL_DIR -type f -exec chmod g+w {} \;
 
# allow wordpress to manage wp-config.php (but prevent world access)
chgrp $APACHE_GROUP $INSTALL_DIR/wp-config.php
chmod 660 $INSTALL_DIR/wp-config.php
 
# allow wordpress to manage .htaccess
touch $INSTALL_DIR/.htaccess
chown $APACHE_GROUP $INSTALL_DIR/.htaccess
chmod 664 $INSTALL_DIR/.htaccess
 
# allow wordpress to manage wp-content
find $INSTALL_DIR/wp-content -exec chown $APACHE_USER:$APACHE_GROUP {} \;
find $INSTALL_DIR/wp-content -type d -exec chmod 775 {} \;
find $INSTALL_DIR/wp-content -type f -exec chmod 664 {} \;
 
cd $INSTALL_DIR
chown root:root wp-config.php
 
echo "**** Done ****"