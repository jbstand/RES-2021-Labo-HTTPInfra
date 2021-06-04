# Docker Container running a reverse proxy server
- ## Docker Container running a reverse proxy server
    + [Description](#description)
    + [Configuration](#configuration)
        * [Dockerfile](#dockerfile)
        * [Nginx](#nginx)
          + [nginx.conf](#nginxconf)
          + [conf.d/default.conf](#confd-defaultconf)
    + [Instructions to setup container](#instructions-to-setup-container)
        * [Build images](#build-images)
        * [Run containers](#run-containers)
    + [Accessing content](#accessing-content)

### Description

The docker image of our reverse proxy is based on [Nginx](https://hub.docker.com/_/nginx) contains a configuration to dispatch request to the right container. The server has two endpoint : ***\*/\****, which redirect to the static docker and the second endpoint : **/api/student**. The port exposed is the default HTTP port which is 80.

### Configuration	

##### Dockerfile

![](img/dockerfile.PNG)

1. We take the latest Nginx image from the Docker Hub
2. We copy the server configuration in the docker image of Nginx server
3. As we wanted to have an evolutive architecture, we copy specific sub-configuration that are included in the Nginx configuration
4. We update the package repository of our image operating system
5. We install vim to be able to debug the Nginx server
6. We are exposing our traffic to the default HTTP port, 80

##### Nginx

###### nginx.conf

![](img/nginx.PNG)

- **events** : this statement is mandatory in the configuration. It is for setting the context of our server. Here we don't need any particular global options
- **http** : 
  - **include** : to be able to support all the MIME types encoding
  - **log_format** : to get logs in the windows where you run the container
  - **access_log** : logs on the server
  - **include** : including all sub configurations

###### conf.d/default.conf

![](img/default.PNG)

- **listen** : server is listenning to the port 80
- **location /** : all request starting with **/** will get redirected to the static container
- **location = /api/student/** & **location = /api/student** : all request that are stricly /api/student or /api/student/ will get redirected to the dynamic container

### Instructions to setup container

##### Build backend images

To setup the infrastructure  you first need to build the image of our static website :

```shell
docker build -t melmot/static static/ #if you're at the root of the project
```

Then you need to build our dynamic REST API :

```shell
docker build -t melmot/dynamic dynamic/ #if you're at the root of the project
```

##### Run backend containers

First, you need to run the static container without exposing the ports :

```
docker run melmot/static 
```

Then you can write down it's IP :

```
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' melmot/static
```

Second, you need to run the dynamic container without exposing the ports : 

```
docker run melmot/dynamic 
```

Then you can write down it's IP :

```
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' melmot/dynamic
```

### Build reverse proxy image

Update the nginx configuration file (reverse/conf/conf.d/default.conf) with the IPs of the static and dynamic containers.

Then build the reverse proxy image : 

```shell
docker build -t melmot/reverse reverse/ #if you're at the root of the project
```

### Run reverse proxy container

Finally, you need to run the reverse proxy container exposing the ports to be able to contact it : 

```
docker run -p %your_local_port%:80 melmot/reverse 
```

We already create a little script (**setup.sh**) at the root of the project to do the all the steps above, mapping the reverse proxy on the port **2222**.

### Accessing content

To access the static container content, you have to go to :

```
http://localhost:%your_local_port%/
```

and to access our dynamic container content, you have to go to : 

```
http://localhost:%your_local_port%/api/student
```

