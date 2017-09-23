# docker-LAMP
defines a docker container running Arch Linux with the LAMP stack installed

## Usage

1. [**Install docker**](https://docs.docker.com/installation/)
1. **Download and start the LAMP server instance**  
`docker run --name lampdev -p 443:443 -d greyltc/lamp:dev`
1. **Test the LAMP server**  
Point your browser to:  
https://localhost/  
if you've not used your own ssl certificate you'll likely see browser warnings here about NET::ERR_CERT_AUTHORITY_INVALID click though those and
you should see the default apache index. Follow the info.php link there and you should see detials of the php installation.
1. **[Optional] Change your webserver root data storage location**  
It's likely desirable for your www root dir to be placed in a persistant storage location outside the docker container, on the host's file system for example. Let's imagine you wish to store your www files in a folder `~/www` on the host's file system. Then insert the following into the docker startup command (from step 2. above) between `run` and `--name`:  
`-v ~/www:/srv/http`  
UID 33 or GID 33 (http in the container image) must have at least read permissions for `~/www` on the host system. Generally, it's enough to do:  
`chmod -R 770 ~/www; sudo chgrp -R 33 ~/www`  
[Read this if you run into permissions issues in the container.](http://stackoverflow.com/questions/24288616/permission-denied-on-accessing-host-directory-in-docker)
1. **[Optional] Use your own ssl certificate**  
This image comes with a self-generated ssl certificate and so you'll get browser warnings when you access your server via https (but the connection will be encrypted with a private key that anyone can view by snooping around in the docker image). You can (& should) replace these self signed certificates with your own, properly generated cert files.
Assuming you have `server.crt` and `server.key` files in a directory `~/sslCert` on the host machine:   
`sudo chown -R root ~/sslCert; sudo chgrp -R root ~/sslCert`  
`sudo chmod 400 ~/sslCert/server.key`   
You can then add `-v ~/sslCert:/root/sslKeys` to the docker run command line to use your ssl certificate files.  
1. **[Optional] Use the built in certbot client to fetch proper ssl certificate files from Let's Encrypt**
Follow the instructions here: https://github.com/greyltc/docker-LAMP/wiki/Using-the-built-in-certbot-client-to-fetch-proper-ssl-certificate-files-from-Let's-Encrypt
1. **[Optional] Stop the lamp docker server instance**  
`docker stop lamp`
1. **[Optional] Delete the lamp docker server instance (after stopping it)**  
`docker rm lamp`
1. **Profit.**
