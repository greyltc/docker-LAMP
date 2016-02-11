#/usr/bin/env bash

# install apache
pacman -S --noprogressbar --noconfirm --needed apache
sed -i '$a ServerName ${HOSTNAME}' /etc/httpd/conf/httpd.conf

# install php
pacman -S --noprogressbar --noconfirm --needed php php-apache

# setup php
cat > /srv/http/info.php <<EOF
<?php
// Show all information, defaults to INFO_ALL
phpinfo();

// Show just the module information.
// phpinfo(8) yields identical results.
phpinfo(INFO_MODULES);
?>
EOF
sed -i 's,LoadModule mpm_event_module modules/mod_mpm_event.so,#LoadModule mpm_event_module modules/mod_mpm_event.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,LoadModule dir_module modules/mod_dir.so,LoadModule dir_module modules/mod_dir.so\nLoadModule php7_module modules/libphp7.so,g' /etc/httpd/conf/httpd.conf
sed -i '$a Include conf/extra/php7_module.conf' /etc/httpd/conf/httpd.conf
sed -i 's,;extension=iconv.so,extension=iconv.so,g' /etc/php/php.ini
sed -i 's,;extension=xmlrpc.so,extension=xmlrpc.so,g' /etc/php/php.ini
sed -i 's,;extension=zip.so,extension=zip.so,g' /etc/php/php.ini
sed -i 's,;extension=bz2.so,extension=bz2.so,g' /etc/php/php.ini
sed -i 's,;extension=curl.so,extension=curl.so,g' /etc/php/php.ini
sed -i 's,;extension=ftp.so,extension=ftp.so,g' /etc/php/php.ini

# for php-ldap
pacman -S --noprogressbar --noconfirm --needed php-ldap
sed -i 's,;extension=ldap.so,extension=ldap.so,g' /etc/php/php.ini

# for php-gd
pacman -S --noprogressbar --noconfirm --needed php-gd
sed -i 's,;extension=gd.so,extension=gd.so,g' /etc/php/php.ini

# for php-intl
pacman -S --noprogressbar --noconfirm --needed php-intl
sed -i 's,;extension=intl.so,extension=intl.so,g' /etc/php/php.ini

# for php-mcrypt
pacman -S --noprogressbar --noconfirm --needed php-mcrypt
sed -i 's,;extension=mcrypt.so,extension=mcrypt.so,g' /etc/php/php.ini

# for PHP caching
sed -i 's,;zend_extension=opcache.so,zend_extension=opcache.so,g' /etc/php/php.ini
# TODO: think about setting default values https://secure.php.net/manual/en/opcache.installation.php#opcache.installation.recommended
pacman -S --noprogressbar --noconfirm --needed php-apcu
sed -i 's,;extension=apcu.so,extension=apcu.so,g' /etc/php/conf.d/apcu.ini
sed -i '$a apc.enabled=1' /etc/php/conf.d/apcu.ini
sed -i '$a apc.shm_size=32M' /etc/php/conf.d/apcu.ini
sed -i '$a apc.ttl=7200' /etc/php/conf.d/apcu.ini

# for exif support
pacman -S --noprogressbar --noconfirm --needed exiv2
sed -i 's,;extension=exif.so,extension=exif.so,g' /etc/php/php.ini

# for sqlite database
pacman -S --noprogressbar --noconfirm --needed sqlite php-sqlite
sed -i 's,;extension=sqlite3.so,extension=sqlite3.so,g' /etc/php/php.ini
sed -i 's,;extension=pdo_sqlite.so,extension=pdo_sqlite.so,g' /etc/php/php.ini

# for mariadb (mysql) database
# here is a hack to prevent an error during install because of missing systemd
ln -s /usr/bin/true /usr/bin/systemd-tmpfiles
pacman -S --noprogressbar --noconfirm --needed mariadb
rm /usr/bin/systemd-tmpfiles
pacman -S --noprogressbar --noconfirm --needed perl-dbd-mysql
sed -i 's,;extension=pdo_mysql.so,extension=pdo_mysql.so,g' /etc/php/php.ini
sed -i 's,;extension=mysql.so,extension=mysql.so,g' /etc/php/php.ini
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
#sed -i 's,mysql.trace_mode = Off,mysql.trace_mode = On,g' /etc/php/php.ini
#sed -i 's,mysql.default_host =,mysql.default_host = localhost,g' /etc/php/php.ini
#sed -i 's,mysql.default_user =,mysql.default_user = root,g' /etc/php/php.ini

# for postgresql
pacman -S --noprogressbar --noconfirm --needed php-pgsql
sed -i 's,;extension=pdo_pgsql.so,extension=pdo_pgsql.so,g' /etc/php/php.ini
sed -i 's,;extension=pgsql.so,extension=pgsql.so,g' /etc/php/php.ini

# for dav suppport
sed -i 's,#LoadModule dav_module modules/mod_dav.so,LoadModule dav_module modules/mod_dav.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,#LoadModule dav_fs_module modules/mod_dav_fs.so,LoadModule dav_fs_module modules/mod_dav_fs.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,#LoadModule dav_lock_module modules/mod_dav_lock.so,LoadModule dav_lock_module modules/mod_dav_lock.so,g' /etc/httpd/conf/httpd.conf
sed -i '$a DAVLockDB /home/httpd/DAV/DAVLock' /etc/httpd/conf/httpd.conf
mkdir -p /home/httpd/DAV
chown -R http:http /home/httpd/DAV
mkdir -p /home/httpd/html/dav
chown -R http:http /home/httpd/html/dav

# setup ssl
bash /root/setupSSL.sh

# generate/fetch ssl cert. files
pacman -S --noprogressbar --noconfirm --needed letsencrypt letsencrypt-apache
setup-apache-ssl-key

# reduce docker layer size
cleanup-image
