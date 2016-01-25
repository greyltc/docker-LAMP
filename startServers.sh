#!/usr/bin/env bash

if [ "$ENABLE_DAV" = true ] ; then
  cat >> /etc/httpd/conf/httpd.conf <<EOF
Alias /dav "/home/httpd/html/dav"

<Directory "/home/httpd/html/dav">
  DAV On
  AllowOverride None
  Options Indexes FollowSymLinks
  Require all granted
</Directory>
EOF
fi

# this folder is normally created by the systemd apache service which we won't be using
mkdir -p /run/httpd

[ "$START_MYSQL" = true ] && cd /usr && /usr/bin/mysqld_safe --datadir=/var/lib/mysql&
[ "$DO_SSL_SELF_GENERATION" = true ] && /usr/sbin/setupApacheSSLKey.sh
[ "$START_APACHE" = true ] && apachectl start
[ "$DO_SSL_LETS_ENCRYPT_FETCH" = true ] && /usr/sbin/setupApacheSSLKey.sh

# hang out right here until the image is terminated
sleep infinity
