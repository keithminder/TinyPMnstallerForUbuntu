#! /bin/sh

TINYPMVERSION=2.6.2

# from /etc/init.d/tomcat6
NAME=tomcat6
# Directory where the Tomcat 6 binary distribution resides
CATALINA_HOME=/usr/share/$NAME
# Directory for per-instance configuration files and webapps
CATALINA_BASE=/var/lib/$NAME

TEMPDIR=`cd $(mktemp -d tinypm-$TINYPMVERSION-XXXX) && pwd`
cd $TEMPDIR

function install_system_packages {
echo "install system packages"
#apt-get -y remove rpl default-jre tomcat6 tomcat6-admin tomcat6-common mysql-server-5.5 mysql-client-5.5 libmysql-java openjdk-6-jdk

apt-get -y install rpl default-jre tomcat6 tomcat6-admin tomcat6-common mysql-server-5.5 mysql-client-5.5 libmysql-java openjdk-6-jdk
}

function download_tinypm {
echo "downloading tinypm"
wget http://www.tinypm.com/downloads/tinypm-$TINYPMVERSION-tomcat6.0.zip
unzip tinypm-$TINYPMVERSION-tomcat6.0.zip
}

function create_database {

read -p "Enter database username for the tinypmdb user: " USERNAME
read -s -p "Enter database password for tinypmdb user: " DBPASSWD
echo "Now enter the MySql root password"
echo "creating database"
cat  > tinypmdb.sql <<EOF 
CREATE DATABASE tinypmdb CHARACTER SET = 'utf8' COLLATE = 'utf8_general_ci';

GRANT SELECT, UPDATE, INSERT, DELETE ON tinypmdb.* TO '$USERNAME'@'localhost' IDENTIFIED BY '$DBPASSWD';

FLUSH PRIVILEGES;
\u tinypmdb
\. sql/mysql/create_schema-$TINYPMVERSION.sql
\. sql/mysql/create_data-$TINYPMVERSION.sql
EOF

# enter your mysql root password here
mysql -u root -p < tinypmdb.sql 
}

function copy_files {
cp dependencies/* $CATALINA_HOME/lib/

mkdir $CATALINA_BASE/webapps/tinypm
unzip tinypm.war -d $CATALINA_BASE/webapps/tinypm/

cd /usr/share/tomcat6/lib
ln -s ../../java/mysql-connector-java.jar  mysql-connector-java.jar
}

function post_install {
chown tomcat6:tomcat6 /usr/share/tomcat6/lib/*
mkdir /var/search_index /var/search_index/tinypm
chown -R tomcat6:tomcat6 /var/search_index

rpl '#hibernate.search.default.indexBase = /var/search_index/tinypm' 'hibernate.search.default.indexBase = /var/search_index/tinypm' $CATALINA_BASE/webapps/tinypm/WEB-INF/classes/hibernate.properties

rpl '#hibernate.search.default.indexBase = /var/search_index/tinypm' 'hibernate.search.default.indexBase = /var/search_index/tinypm' $CATALINA_BASE/webapps/tinypm/WEB-INF/classes/hibernate.properties

rpl 'hibernate.connection.username = username' 'hibernate.connection.username = '$USERNAME $CATALINA_BASE/webapps/tinypm/WEB-INF/classes/hibernate.properties

rpl 'hibernate.connection.password = password' 'hibernate.connection.password = '$DBPASSWD $CATALINA_BASE/webapps/tinypm/WEB-INF/classes/hibernate.properties

/etc/init.d/tomcat6 restart


echo "point your browser to http://localhost:8080/tinypm/"
echo "installation files are left for inspection in $TEMPDIR"
}

install_system_packages &&
download_tinypm &&
create_database &&
copy_files &&
post_install


