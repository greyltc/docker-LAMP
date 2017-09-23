FROM greyltc/archlinux
MAINTAINER Grey Christoforo <grey@christoforo.net>

ADD install-lamp.sh /usr/sbin/install-lamp
RUN install-lamp

# generate our ssl key
ADD setupApacheSSLKey.sh /usr/sbin/setup-apache-ssl-key
ENV DO_SSL_SELF_GENERATION true
ENV SUBJECT /C=US/ST=CA/L=CITY/O=ORGANIZATION/OU=UNIT/CN=localhost
ENV DO_SSL_LETS_ENCRYPT_FETCH false
ENV EMAIL fail
RUN setup-apache-ssl-key
ENV DO_SSL_SELF_GENERATION false
ENV CURLOPT_CAINFO /etc/ssl/certs/ca-certificates.crt

# here are the ports that various things in this container are listening on
# for http (apache, only if APACHE_DISABLE_PORT_80 = false)
#EXPOSE 80
# for https (apache)
EXPOSE 443
# for postgreSQL server (only if START_POSTGRESQL = true)
EXPOSE 5432
# for MySQL server (mariadb, only if START_MYSQL = true)
EXPOSE 3306

# start servers
ADD startServers.sh /usr/sbin/start-servers
ENV START_APACHE true
ENV APACHE_DISABLE_PORT_80 true
ENV START_MYSQL true
ENV START_POSTGRESQL false
ENV ENABLE_DAV false
ENV ENABLE_CRON true
CMD start-servers; sleep infinity
