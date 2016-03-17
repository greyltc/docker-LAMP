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

# the systemd services generally create these folders, make them now manually
mkdir -p /run/httpd
mkdir -p /run/postgresql && chown postgres /run/postgresql

[ "$START_POSTGRESQL" = true ] && su postgres -c 'pg_ctl -s -D /var/lib/postgres/data start -w -t 120'
[ "$START_MYSQL" = true ] && cd /usr && /usr/bin/mysqld_safe --datadir=/var/lib/mysql&
[ "$DO_SSL_SELF_GENERATION" = true ] && setup-apache-ssl-key
[ "$START_APACHE" = true ] && apachectl start
[ "$DO_SSL_LETS_ENCRYPT_FETCH" = true ] && setup-apache-ssl-key
[ "$ENABLE_CRON" = true ] && crond
