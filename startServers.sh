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

[ "$START_MYSQL" = true ] && cd /usr && /usr/bin/mysqld_safe --datadir=/var/lib/mysql&
[ "$REGENERATE_SSL_CERT" = true ] && /etc/httpd/conf/genSSLKey.sh
[ "$START_APACHE" = true ] && apachectl start

# hang out right here until the image is terminated
sleep infinity
