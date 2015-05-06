#!/usr/bin/env bash


[ "$START_MYSQL" = true ] && cd /usr && /usr/bin/mysqld_safe --datadir=/var/lib/mysql&
[ "$REGENERATE_SSL_CERT" = true ] && /etc/httpd/conf/genSSLKey.sh
[ "$START_APACHE" = true ] && apachectl start

# hang out right here until the image is terminated
sleep infinity
