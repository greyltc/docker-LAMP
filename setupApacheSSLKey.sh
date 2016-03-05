#!/usr/bin/env bash

# here we assume that the environment provides $HOSTNAME and possibly $SUBJECT (if self-generating) for example:
# SUBJECT='/C=US/ST=CA/L=CITY/O=ORGANIZATION/OU=UNIT/CN=localhost'

CERT_DIR=/root/sslKeys
APACHE_SSL_CONF=/etc/httpd/conf/extra/httpd-ssl.conf
CRT_FILE_NAME=server.crt
KEY_FILE_NAME=server.key
CSR_FILE_NAME=server.csr

# let's make a folder to hold our ssl cert files
mkdir -p ${CERT_DIR}

# let's tell apache to look for ssl cert files (called server.crt and server.key) in this folder
sed -i "s,/etc/httpd/conf/server.crt,${CERT_DIR}/${CRT_FILE_NAME},g" ${APACHE_SSL_CONF}
sed -i "s,/etc/httpd/conf/server.key,${CERT_DIR}/${KEY_FILE_NAME},g" ${APACHE_SSL_CONF}
# the intention here is that, prior to starting apache, there will somehow be two files in this folder for it to use
# these files might be self-generated, fetched from letsencrypt.org or
# put there by the user

if [ "$DO_SSL_SELF_GENERATION" = true ] ; then
  # edit this if you don't want your self generated cert files to be valid for 10 years
  DAYS_VALID=3650
  echo "Self generating SSL cert. files..."
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out ${CERT_DIR}/${KEY_FILE_NAME}
  openssl req -new -key ${CERT_DIR}/${KEY_FILE_NAME} -out ${CERT_DIR}/${CSR_FILE_NAME} -subj $SUBJECT
  openssl x509 -req -days ${DAYS_VALID} -in ${CERT_DIR}/${CSR_FILE_NAME} -signkey ${CERT_DIR}/${KEY_FILE_NAME} -out ${CERT_DIR}/${CRT_FILE_NAME}
  apachectl graceful || true
fi

if [ "$DO_SSL_LETS_ENCRYPT_FETCH" = true ] ; then
  HOSTNAME=$(hostname --fqdn)
  echo "Fetching ssl certificate files for ${HOSTNAME} from letsencrypt.org."
  echo "This container's Apache server must be reachable from the Internet via http://${HOSTNAME}"
  letsencrypt --debug certonly --agree-tos --renew-by-default --email ${EMAIL} --webroot -w /srv/http -d ${HOSTNAME}
  if [ $? -eq 0 ]; then
    rm -rf ${CERT_DIR}/${CRT_FILE_NAME}
    ln -s /etc/letsencrypt/live/${HOSTNAME}/cert.pem ${CERT_DIR}/${CRT_FILE_NAME}
    rm -rf ${CERT_DIR}/${KEY_FILE_NAME}
    ln -s /etc/letsencrypt/live/${HOSTNAME}/privkey.pem ${CERT_DIR}/${KEY_FILE_NAME}
    apachectl graceful
  else
    echo "Failed to fetch ssl cert from let's encrypt"
  fi
fi

# let's make sure the key file is really a secret
chmod 600 ${CERT_DIR}/${KEY_FILE_NAME}
