#!/bin/bash

#Asking for name and password with confirmation.

while [ true ]
do

read -p "Please enter a name for the new user : " name

echo ""

read -p "Please enter a password for the new user : " password

echo ""

read -p "So $name and $password is that correct? y/n : " answer
echo ""

if [[ ( $answer == "y" ) ]];

then 
break

fi

done

#Creating the FTP user
#echo "$password" | sudo htpasswd -i -m /etc/vsftpd/ftpd.passwd $name
sudo htpasswd -p -b /etc/vsftpd/ftpd.passwd $name $(openssl passwd -1 -noverify $password) &>/dev/null

#Restart FTP service
sudo service vsftpd restart

#Create maps for the user
sudo mkdir /var/www/$name
sudo chmod -w /var/www/$name
sudo mkdir /var/www/$name/www
sudo chmod -R 755 /var/www/$name/www
sudo chown -R vsftpd:nogroup /var/www/$name

#Create database with login for the user.
sudo mysql -uroot -pVMware123! <<MYSQL_SCRIPT &>/dev/null
CREATE DATABASE $name;
CREATE USER '$name'@'localhost' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

#Add a virtual host to apache2
sudo bash -c 'echo -e "<VirtualHost *:80> \n\n ServerName "'$name'".team7.com \n ServerAdmin me@example.com \n\n DocumentRoot /var/www/"'$name'"/www \n\n <directory /var/www/"'$name'"/www> \n Options -Indexes +FollowSymLinks \n AllowOverride All \n </directory> \n\n ErrorLog \${APACHE_LOG_DIR}/error.log \n CustomLog \${APACHE_LOG_DIR}access.log combined \n </VirtualHost>" > /etc/apache2/sites-available/'$name.team7.com.conf''

#enable the new site and restart apache2
sudo a2ensite $name.team7.com.conf
sudo service apache2 restart
