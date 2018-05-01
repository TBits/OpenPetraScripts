#!/bin/bash
# Author: Timotheus Pokorra <tp@tbits.net>
# Copyright: 2017-2018 TBits.net
# Description: setup a development environment
#        this assumes that reinstall.sh has been run

yum -y install nant mono-devel

curl --silent --location https://rpm.nodesource.com/setup_8.x  | bash -
yum -y install nodejs
#node --version
#8.9.4
#npm --version
#5.6.0

# support for corporate http web proxy
if [ ! -z "$http_proxy" ]
then
  # this will write to ~/.npmrc
  npm config set proxy $http_proxy
fi
if [ ! -z "$https_proxy" ]
then
  # this will write to ~/.npmrc
  npm config set https-proxy $https_proxy
fi

npm install -g browserify
npm install -g uglify-es

cd ~

if [ ! -d openpetra ]
then
  git clone --depth 10 http://github.com/tbits/openpetra.git -b test
fi

if [ ! -d openpetra-client-js ]
then
  git clone https://github.com/tbits/openpetra-client-js.git -b test
fi

cd openpetra

# get the database password from the default server installed by reinstall.sh
dbpwd=`cat /home/openpetra/etc/PetraServerConsole.config  | grep Server.DBPassword | awk -F\" '{print $4;}'`
cat > OpenPetra.build.config <<FINISH
<?xml version="1.0"?>
<project name="OpenPetra-userconfig">
    <!-- DB password from /home/openpetra/etc/PetraServerConsole.config -->
    <property name="DBMS.Type" value="mysql"/>
    <property name="DBMS.Password" value="$dbpwd"/>
    <property name="Server.DebugLevel" value="0"/>
</project>
FINISH

# add symbolic link from /usr/local/openpetra/client to /root/openpetra-client-js
rm -Rf /usr/local/openpetra/client
ln -s /root/openpetra-client-js /usr/local/openpetra/client
chmod a+rx /root

cd ~/openpetra-client-js
npm install

# install phpMyAdmin with PHP7.1
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils
yum-config-manager --enable remi-php71
yum-config-manager --enable remi
yum -y install phpMyAdmin php-fpm
sed -i "s#user = apache#user = nginx#" /etc/php-fpm.d/www.conf
sed -i "s#group = apache#group = nginx#" /etc/php-fpm.d/www.conf
sed -i "s#listen = 127.0.0.1:9000#listen = 127.0.0.1:8080#" /etc/php-fpm.d/www.conf
sed -i "s#;chdir = /var/www#chdir = /usr/share/phpMyAdmin#" /etc/php-fpm.d/www.conf
chown nginx:nginx /var/lib/php/session
systemctl enable php-fpm
systemctl start php-fpm
if [[ -z "`cat /etc/nginx/conf.d/openpetra.conf | grep phpMyAdmin`" ]];
then
  sed -i "s#location / {#location / {\n         rewrite ^/phpmyadmin.*$ /phpMyAdmin redirect;#g" /etc/nginx/conf.d/openpetra.conf
  sed -i "s#^}##g" /etc/nginx/conf.d/openpetra.conf
  cat >> /etc/nginx/conf.d/openpetra.conf <<FINISH
    location /phpMyAdmin {
         root /usr/share/;
         index index.php index.html index.htm;
         location ~ ^/phpMyAdmin/(.+\.php)$ {
                   root /usr/share/;
                   fastcgi_pass 127.0.0.1:8080;
                   fastcgi_index index.php;
                   include /etc/nginx/fastcgi_params;
                   fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }
    }
}
FINISH
fi

systemctl reload nginx

echo "now run in ~/openpetra: nant generateSolution install"

