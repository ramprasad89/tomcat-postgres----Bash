#!/bin/bash

tomcat_home="/usr/share/tomcat6"
echo "Please enter the root password for YUM to start install the package"
sudo bash

echo "Installing the tomcat6 package"
yum install tomcat6 -y

echo "Downloading the war file"
wget -O $tomcat_home/webapps/ROOT.war http://env.cliqrtech.com/deepak/ROOT.war

echo "Changing the port number"
sed -in '69s/8080/80/' $tomcat_home/conf/server.xml

echo "Installing Apache and using it as reverse porxy"
yum install httpd -y

echo "Updating apache config file"
echo "RewriteEngine On" >> /etc/httpd/conf/httpd.conf
echo "RewriteRule ^/(.*)$ ajp://localhost:8009/$1 [P,QSA,L]" >> /etc/httpd/conf/httpd.conf

echo "Starting Apache"
service httpd start
chkconfig httpd on

if [ `ps -ef | grep httpd | grep -v grep | wc -l` -eq 1 ]
then
	echo "Apache is running"
else
	echo "Apache is not running"
fi

echo "Starting tomcat"
service tomcat6 start
chkconfig tomcat6 on

echo "Site can be accessed using url : http://localhost:80"

if [ `ps -ef | grep tomcat6 | grep -v grep | wc -l` -eq 1 ]
then
	echo "Tomcat is running"
else
	echo "Tomcat is not running"
fi

echo "Creating a postgres user"
adduser postgres

mkdir /var/pgsql
chown postgres.postgres /var/pgsql
chmod 750 /var/pgsql

echo "Installing Postgresql database"
yum install postgresql-libs postgresql postgresql-server -y

echo "Changing config file"
sed -in '/PGDATA/c\PGDATA=\/var\/pgsql' /etc/init.d/postgresql
sed -in '/PGLOG/c\PGLOG=\/var\/pgsql\/pgstartup.log' /etc/init.d/postgresql

su postgres
initdb -D /var/pgsql/data
exit

echo "Initializing and starting postgresql"
service postgresql initdb
service postgresql start
chkconfig postgresql on

if [ `ps -ef | grep pgsql | wc -l` -eq 1 ]
then
	echo "Postgresql is running"
else
	echo "Postgresql is not running"
fi


echo "Changing postgres user password"
su - postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password 'welcome1';\""

echo "Creating queueman database"
sudo -u postgres bash -c "psql -c \"CREATE DATABASE queueman;\""

echo "Restoring the queueman database"
su - postgres
wget http://env.cliqrtech.com/deepak/queueman.sql
psql queueman < queueman.sql
exit

echo "Changing JDBC connection properties"
sed -in '/databaseurl/c\jdbc.databaseurl=jdbc:postgresql:\/\/localhost:5432\/queueman' $tomcat_home/webapps/ROOT/WEB-INF/jdbc.properties
sed -in '/password/c\jdbc.password=welcome1' $tomcat_home/webapps/ROOT/WEB-INF/jdbc.properties


#Port below 1024 are previliged ports and cannot be used by any other user other than root.
#so tomcat user cannot run port 80, its better to use apache with a rewrite rule to go to tomcat
#Ref: http://stackoverflow.com/questions/5544713/starting-tomcat-on-port-80-on-centos-release-5-5-final
