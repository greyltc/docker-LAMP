#/usr/bin/env bash

# install apache
pacman -S --noprogressbar --noconfirm --needed apache
sed -i '$a ServerName ${HOSTNAME}' /etc/httpd/conf/httpd.conf

# enable mod rewrite
sed -i '/^#LoadModule rewrite_module modules\/mod_rewrite.so/s/^#//g' /etc/httpd/conf/httpd.conf

# solve HTTP TRACE vulnerability: http://www.kb.cert.org/vuls/id/867593
sed -i '$a TraceEnable Off' /etc/httpd/conf/httpd.conf

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
sed -i 's,;extension=gettext.so,extension=gettext.so,g' /etc/php/php.ini

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
sed -i '$a apc.enable_cli=1' /etc/php/conf.d/apcu.ini
sed -i '$a apc.enabled=1' /etc/php/conf.d/apcu.ini
sed -i '$a apc.shm_size=32M' /etc/php/conf.d/apcu.ini
sed -i '$a apc.ttl=7200' /etc/php/conf.d/apcu.ini

# enable APC backwards compatibility
#pacman -S --noconfirm --noprogress --needed php-apcu-bc
#sed -i 's,;extension=apc.so,extension=apc.so,g' /etc/php/conf.d/apcu.ini

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
sed -i 's,;extension=mysqli.so,extension=mysqli.so,g' /etc/php/php.ini
#sed -i 's,mysql.trace_mode = Off,mysql.trace_mode = On,g' /etc/php/php.ini
#sed -i 's,mysql.default_host =,mysql.default_host = localhost,g' /etc/php/php.ini
#sed -i 's,mysql.default_user =,mysql.default_user = root,g' /etc/php/php.ini

# for postgresql
pacman -S --noprogressbar --noconfirm --needed postgresql php-pgsql
su postgres -c "initdb --locale en_US.UTF-8 -E UTF8 -D '/var/lib/postgres/data'"
mkdir -p /run/postgresql && chown postgres /run/postgresql
su postgres -c 'pg_ctl -s -D /var/lib/postgres/data start -w -t 120'
su postgres -c 'createuser root'
su postgres -c 'psql --command="ALTER USER root WITH SUPERUSER;"'
su postgres -c '/usr/bin/pg_ctl -s -D /var/lib/postgres/data stop -m fast'
sed -i 's,;extension=pdo_pgsql.so,extension=pdo_pgsql.so,g' /etc/php/php.ini
sed -i 's,;extension=pgsql.so,extension=pgsql.so,g' /etc/php/php.ini

# for dav suppport
sed -i 's,#LoadModule dav_module modules/mod_dav.so,LoadModule dav_module modules/mod_dav.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,#LoadModule dav_fs_module modules/mod_dav_fs.so,LoadModule dav_fs_module modules/mod_dav_fs.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,#LoadModule dav_lock_module modules/mod_dav_lock.so,LoadModule dav_lock_module modules/mod_dav_lock.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,#LoadModule setenvif_module modules/mod_setenvif.so,LoadModule setenvif_module modules/mod_setenvif.so,g' /etc/httpd/conf/httpd.conf
#sed -i 's,#LoadModule auth_digest_module modules/mod_auth_digest.so,LoadModule auth_digest_module modules/mod_auth_digest.so,g' /etc/httpd/conf/httpd.conf
#sed -i 's,#LoadModule authn_core_module modules/mod_authn_core.so,LoadModule authn_core_module modules/mod_authn_core.so,g' /etc/httpd/conf/httpd.conf
#sed -i 's,#LoadModule authn_file_module modules/mod_authn_file.so,LoadModule authn_file_module modules/mod_authn_file.so,g' /etc/httpd/conf/httpd.conf
#sed -i 's,#LoadModule authz_core_module modules/mod_authz_core.so,LoadModule authz_core_module modules/mod_authz_core.so,g' /etc/httpd/conf/httpd.conf
#sed -i 's,#LoadModule authz_user_module modules/mod_authz_user.so,LoadModule authz_user_module modules/mod_authz_user.so,g' /etc/httpd/conf/httpd.conf
#sed -i '$a Include conf/extra/httpd-dav.conf' /etc/httpd/conf/httpd.conf
sed -i 's,Alias /uploads "/etc/httpd/uploads",Alias /dav "/srv/webdav",g' /etc/httpd/conf/extra/httpd-dav.conf
sed -i 's,<Directory "/etc/httpd/uploads">,<Directory "/srv/webdav">,g' /etc/httpd/conf/extra/httpd-dav.conf
# disable auth requirement for dav access
sed -i 's,AuthType Digest,#AuthType Digest,g' /etc/httpd/conf/extra/httpd-dav.conf
sed -i 's,AuthName DAV-upload,#AuthName DAV-upload,g' /etc/httpd/conf/extra/httpd-dav.conf
sed -i 's,AuthUserFile "/etc/httpd/user.passwd",#AuthUserFile "/etc/httpd/user.passwd",g' /etc/httpd/conf/extra/httpd-dav.conf
sed -i 's,AuthDigestProvider file,#AuthDigestProvider file,g' /etc/httpd/conf/extra/httpd-dav.conf
sed -i 's,<RequireAny>,Require all granted,g' /etc/httpd/conf/extra/httpd-dav.conf
sed -i 's,Require method GET POST OPTIONS,#Require method GET POST OPTIONS,g' /etc/httpd/conf/extra/httpd-dav.conf
sed -i 's,Require user admin,Options Indexes FollowSymLinks,g' /etc/httpd/conf/extra/httpd-dav.conf
sed -i 's,</RequireAny>,AllowOverride None,g' /etc/httpd/conf/extra/httpd-dav.conf
mkdir -p /etc/httpd/var/
chown -R http:http /etc/httpd/var/
mkdir -p /srv/webdav
chmod g+w /srv/webdav
chown -R http:http /srv/webdav
chmod g+s /srv/webdav/
setfacl -d -m group:http:rwx /srv/webdav
setfacl -m group:http:rwx /srv/webdav

# setup ssl
sed -i 's,;extension=openssl.so,extension=openssl.so,g' /etc/php/php.ini
sed -i 's,#LoadModule ssl_module modules/mod_ssl.so,LoadModule ssl_module modules/mod_ssl.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so,LoadModule socache_shmcb_module modules/mod_socache_shmcb.so,g' /etc/httpd/conf/httpd.conf
sed -i 's,#Include conf/extra/httpd-ssl.conf,Include conf/extra/httpd-ssl.conf,g' /etc/httpd/conf/httpd.conf
# use Mozilla's recommended ciphersuite (see https://wiki.mozilla.org/Security/Server_Side_TLS):
sed -i 's/^SSLCipherSuite .*/SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK/g' /etc/httpd/conf/extra/httpd-ssl.conf
# disable super old and vulnerable SSL protocols: SSLv2 and SSLv3 (this breaks IE6 & windows XP)
sed -i '$a SSLProtocol All -SSLv2 -SSLv3' /etc/httpd/conf/extra/httpd-ssl.conf

# generate/fetch ssl cert. files
pacman -S --noprogressbar --noconfirm --needed letsencrypt letsencrypt-apache
setup-apache-ssl-key

# instal cron
pacman -S --noprogressbar --noconfirm --needed cronie

# reduce docker layer size
cleanup-image
