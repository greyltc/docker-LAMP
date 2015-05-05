#!/usr/bin/env bash

[ "$START_APACHE" = true ] && apachectl start
[ "$START_MYSQL" = true ] && cd /usr && /usr/bin/mysqld_safe --datadir=/var/lib/mysql
