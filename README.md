# docker-LAMP
defines a docker container running Arch Linux with the LAMP stack installed

## Usage

1. [**Install docker**](https://docs.docker.com/installation/)
1. **Download and test the LAMP server instance**  
`docker run --name lamp -p 80:80 -p 443:443 -d l3iggs/lamp`
1. **Access the docker setup page**  
Point your browser to:  
http://localhost/  
or  
https://localhost/  
and you should see the default apacheindex.
1. **[Optional] Change your webserver root data storage location**  
It's likely desirable for your www root dir to be placed in a persistant storage location outside the docker container, on the host's file system for example. Let's imagine you wish to store your www files in a folder `~/www` on the host's file system. Then insert the following into the docker startup command (from step 2. above) between `run` and `--name`:  
`-v ~/www:/srv/http`  
UID 33 or GID 33 (http in the container image) must have at least read permissions for `~/www` on the host system. 
[Read this if you run into permissions issues in the container.](http://stackoverflow.com/questions/24288616/permission-denied-on-accessing-host-directory-in-docker)
1. **[Optional] Use your own ssl certificate**
This image comes with a self-generated ssl certificate and so you'll get browser warnings when you access owncloud via https. You can replace these self signed certificates with your own, properly generated cert files.
Assuming you have `server.crt` and `server.key` files in a directory `~/sslCert` on the host machine:   
`sudo chown -R root ~/sslCert; sudo chgrp -R root ~/sslCert`  
`sudo chmod 400 ~/sslCert/server.key`   
You can then add `-v ~/sslCert:/https` to the docker run command line to use your ssl certificate files.  
1. **[Optional] Stop the lamp docker server instance**  
`docker stop lamp`
1. **[Optional] Delete the lamp docker server instance (after stopping it)**  
`docker rm lamp`
1. **Profit.**
