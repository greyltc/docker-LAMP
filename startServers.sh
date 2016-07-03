#!/usr/bin/env bash

if [ "$ENABLE_DAV" = true ] ; then
  sed -i '$a Include conf/extra/httpd-dav.conf' /etc/httpd/conf/httpd.conf
else
  sed -i '\/Include conf\/extra\/httpd-dav.conf/d' /etc/httpd/conf/httpd.conf
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
