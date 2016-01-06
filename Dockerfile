FROM l3iggs/archlinux
MAINTAINER l3iggs <l3iggs@live.com>

# install apache
RUN pacman -S --noconfirm --needed apache
RUN sed -i '$a ServerName ${HOSTNAME}' /etc/httpd/conf/httpd.conf

# install php
RUN pacman -S --noconfirm --needed php php-apache
ADD info.php /srv/http/

# for ssl
RUN sed -i 's,;extension=openssl.so,extension=openssl.so,g' /etc/php/php.ini
RUN sed -i 's,#LoadModule ssl_module modules/mod_ssl.so,LoadModule ssl_module modules/mod_ssl.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so,LoadModule socache_shmcb_module modules/mod_socache_shmcb.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,#Include conf/extra/httpd-ssl.conf,Include conf/extra/httpd-ssl.conf,g' /etc/httpd/conf/httpd.conf
# use Mozilla's recommended ciphersuite (see https://wiki.mozilla.org/Security/Server_Side_TLS):
RUN sed -i 's/^SSLCipherSuite .*/SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK/g' /etc/httpd/conf/extra/httpd-ssl.conf
# disable super old and vulnerable SSL protocols: SSLv2 and SSLv3 (this breaks IE6 & windows XP)
RUN sed -i '$a SSLProtocol All -SSLv2 -SSLv3' /etc/httpd/conf/extra/httpd-ssl.conf

# generate a self-signed cert
ENV SUBJECT /C=US/ST=CA/L=CITY/O=ORGANIZATION/OU=UNIT/CN=localhost
ADD genSSLKey.sh /etc/httpd/conf/genSSLKey.sh
RUN /etc/httpd/conf/genSSLKey.sh
RUN mkdir /https
RUN ln -s /etc/httpd/conf/server.crt /https/server.crt
RUN ln -s /etc/httpd/conf/server.key /https/server.key
RUN sed -i 's,/etc/httpd/conf/server.crt,/https/server.crt,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sed -i 's,/etc/httpd/conf/server.key,/https/server.key,g' /etc/httpd/conf/extra/httpd-ssl.conf

# setup php
RUN sed -i 's,LoadModule mpm_event_module modules/mod_mpm_event.so,#LoadModule mpm_event_module modules/mod_mpm_event.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,LoadModule dir_module modules/mod_dir.so,LoadModule dir_module modules/mod_dir.so\nLoadModule php7_module modules/libphp7.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i '$a Include conf/extra/php7_module.conf' /etc/httpd/conf/httpd.conf
RUN sed -i 's,;extension=iconv.so,extension=iconv.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=xmlrpc.so,extension=xmlrpc.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=zip.so,extension=zip.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=bz2.so,extension=bz2.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=curl.so,extension=curl.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=ftp.so,extension=ftp.so,g' /etc/php/php.ini

# for php-ldap
RUN pacman -S --noconfirm --needed php-ldap
RUN sed -i 's,;extension=ldap.so,extension=ldap.so,g' /etc/php/php.ini

# for php-gd
RUN pacman -S --noconfirm --needed php-gd
RUN sed -i 's,;extension=gd.so,extension=gd.so,g' /etc/php/php.ini

# for php-intl
RUN pacman -S --noconfirm --needed php-intl
RUN sed -i 's,;extension=intl.so,extension=intl.so,g' /etc/php/php.ini

# for php-mcrypt
RUN pacman -S --noconfirm --needed php-mcrypt
RUN sed -i 's,;extension=mcrypt.so,extension=mcrypt.so,g' /etc/php/php.ini

# for PHP caching
RUN sed -i 's,;zend_extension=opcache.so,zend_extension=opcache.so,g' /etc/php/php.ini
# TODO: think about setting default values https://secure.php.net/manual/en/opcache.installation.php#opcache.installation.recommended
RUN pacman -S --noconfirm --needed php-apcu
RUN sed -i 's,;extension=apcu.so,extension=apcu.so,g' /etc/php/conf.d/apcu.ini
RUN sed -i '$a apc.enabled=1' /etc/php/conf.d/apcu.ini
RUN sed -i '$a apc.shm_size=32M' /etc/php/conf.d/apcu.ini
RUN sed -i '$a apc.ttl=7200' /etc/php/conf.d/apcu.ini

# for exif support
RUN pacman -S --noconfirm --needed exiv2
RUN sed -i 's,;extension=exif.so,extension=exif.so,g' /etc/php/php.ini

# for sqlite database
RUN pacman -S --noconfirm --needed sqlite php-sqlite
RUN sed -i 's,;extension=sqlite3.so,extension=sqlite3.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=pdo_sqlite.so,extension=pdo_sqlite.so,g' /etc/php/php.ini

# for mariadb (mysql) database
# here is a hack to prevent an error during install because of missing systemd
RUN ln -s /usr/bin/true /usr/bin/systemd-tmpfiles
RUN pacman -S --noconfirm --needed mariadb
RUN rm /usr/bin/systemd-tmpfiles
RUN pacman -S --noconfirm --needed perl-dbd-mysql
RUN sed -i 's,;extension=pdo_mysql.so,extension=pdo_mysql.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=mysql.so,extension=mysql.so,g' /etc/php/php.ini
RUN mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
#RUN sed -i 's,mysql.trace_mode = Off,mysql.trace_mode = On,g' /etc/php/php.ini
#RUN sed -i 's,mysql.default_host =,mysql.default_host = localhost,g' /etc/php/php.ini
#RUN sed -i 's,mysql.default_user =,mysql.default_user = root,g' /etc/php/php.ini

# for postgresql
RUN pacman -S --noconfirm --needed php-pgsql
RUN sed -i 's,;extension=pdo_pgsql.so,extension=pdo_pgsql.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=pgsql.so,extension=pgsql.so,g' /etc/php/php.ini

# for dav suppport
RUN sed -i 's,#LoadModule dav_module modules/mod_dav.so,LoadModule dav_module modules/mod_dav.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,#LoadModule dav_fs_module modules/mod_dav_fs.so,LoadModule dav_fs_module modules/mod_dav_fs.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,#LoadModule dav_lock_module modules/mod_dav_lock.so,LoadModule dav_lock_module modules/mod_dav_lock.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i '$a DAVLockDB /home/httpd/DAV/DAVLock' /etc/httpd/conf/httpd.conf
RUN mkdir -p /home/httpd/DAV
RUN chown -R http:http /home/httpd/DAV
RUN mkdir -p /home/httpd/html/dav
RUN chown -R http:http /home/httpd/html/dav

# expose web server ports
EXPOSE 80
EXPOSE 443

# set some default variables for the startup script
ENV REGENERATE_SSL_CERT false
ENV START_APACHE true
ENV START_MYSQL true
ENV ENABLE_DAV false

# start servers
ADD startServers.sh /root/startServers.sh
CMD ["/root/startServers.sh"]
