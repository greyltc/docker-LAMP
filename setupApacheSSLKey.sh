#!/usr/bin/env bash
set -eu -o pipefail

# here we assume that the environment provides $HOSTNAME and possibly $SUBJECT (if self-generating) for example:
# SUBJECT='/C=US/ST=CA/L=CITY/O=ORGANIZATION/OU=UNIT/CN=localhost'

CERT_DIR=/root/sslKeys
APACHE_SSL_CONF=/etc/httpd/conf/extra/httpd-ssl.conf
CRT_FILE_NAME=fullchain.pem
KEY_FILE_NAME=privkey.pem

# let's make a folder to hold our ssl cert files
mkdir -p ${CERT_DIR}

# let's tell apache to look for ssl cert files (called server.crt and server.key) in this folder
sed -i "s,/etc/httpd/conf/server.crt,${CERT_DIR}/${CRT_FILE_NAME},g" ${APACHE_SSL_CONF}
sed -i "s,/etc/httpd/conf/server.key,${CERT_DIR}/${KEY_FILE_NAME},g" ${APACHE_SSL_CONF}
# the intention here is that, prior to starting apache, there will somehow be two files in this folder for it to use
# these files might be self-generated, fetched from letsencrypt.org or
# put there by the user


link_certbot_keys(){
  rm -rf ${CERT_DIR}/${CRT_FILE_NAME}
  ln -s /etc/letsencrypt/live/${1}/fullchain.pem ${CERT_DIR}/${CRT_FILE_NAME}
  rm -rf ${CERT_DIR}/${KEY_FILE_NAME}
  ln -s /etc/letsencrypt/live/${1}/privkey.pem ${CERT_DIR}/${KEY_FILE_NAME}
  [ -f /var/run/httpd/httpd.pid ] && apachectl graceful
  echo "Success!"
  echo "Now you could copy your cert files out of the image and save them somewhere safe:"
  echo "docker cp CONTAINER:/etc/letsencrypt ~/letsencryptBackup"
  echo "where CONTAINER is the name you used when you started the container"
  # now we'll schedule renewals via cron twice per day (will only be successful after ~90 days)
  echo '51 6,15 * * * root certbot renew >> /var/log/certbot.log 2>&1' > /etc/cron.d/certbot_renewal
}

if [ "$DO_SSL_SELF_GENERATION" = true ] ; then
  # edit this if you don't want your self generated cert files to be valid for 10 years
  DAYS_VALID=3650
  CSR_FILE_NAME=server.csr
  echo "Self generating SSL cert. files..."
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out ${CERT_DIR}/${KEY_FILE_NAME}
  openssl req -new -key ${CERT_DIR}/${KEY_FILE_NAME} -out ${CERT_DIR}/${CSR_FILE_NAME} -subj $SUBJECT
  openssl x509 -req -days ${DAYS_VALID} -in ${CERT_DIR}/${CSR_FILE_NAME} -signkey ${CERT_DIR}/${KEY_FILE_NAME} -out ${CERT_DIR}/${CRT_FILE_NAME}
  [ -f /var/run/httpd/httpd.pid ] && apachectl graceful || true
fi

if [ "$DO_SSL_LETS_ENCRYPT_FETCH" = true ] ; then
  : ${HOSTNAME:=$(hostname --fqdn)}
  echo "Fetching ssl certificate files for ${HOSTNAME} from letsencrypt.org."
  echo "This container's Apache server must be reachable from the Internet via https://${HOSTNAME}"
  certbot --non-interactive --apache --debug --agree-tos --email ${EMAIL} -d ${HOSTNAME} certonly
  if [ $? -eq 0 ]; then
    link_certbot_keys $HOSTNAME
  else
    echo "Failed to fetch ssl cert from let's encrypt"
  fi
fi

# do this when you've volume mapped previously fetched let's encrypt files into the container
if [ "$USE_EXISTING_LETS_ENCRYPT" = true ] ; then
  echo "SSL setup with existing Let's Encrypt cert"
  HOSTNAME="$(find /etc/letsencrypt/live/. -type d | sed -n 2p)"
  if [ -d "$HOSTNAME" ]; then
    certbot renew
    link_certbot_keys $(basename $HOSTNAME)
    echo "Done."
  else
    echo "Could not find previously fetched Let's Encrypt files!"
    echo "Did you volume map them into the container properly?"
  fi
fi

# let's make sure the key file is really a secret
chmod 600 ${CERT_DIR}/${KEY_FILE_NAME}
