# Docker Container running multiple servers and a dynamic proxy with load-balancing (sticky session) to distribute the traffic.

- ## Docker Container running multiple servers and a dynamic proxy with load-balancing (sticky session) to distribute the traffic.

  + [Description](#description)
  + [Configuration](#configuration)
    * [Dockerfile](#dockerfile)
    * [Setup Nginx](#setup_nginx)
    * [Nginx](#nginx)
      + [nginx.conf](#nginxconf)
      + [conf.d/default.conf](#confd-defaultconf)
  + [Instructions to setup container](#instructions-to-setup-container)
    * [Build images](#build-images)
    * [Run containers](#run-containers)
  + [Accessing content](#accessing-content)

### Description

The docker image of our dynamic reverse proxy is based on [Nginx](https://hub.docker.com/_/nginx) contains a configuration to dispatch request to the right container. The server has two endpoint : ***\*/\****, which redirect to the static docker and the second endpoint : **/api/student**. The port exposed is the default HTTP port which is 80.

The page served by the static HTTP server is updated with the informations fetched (with AJAX queries, every two seconds) from the dynamic HTTP server.

We configured the Nginx server for load-balancing between various static and dynamic backend, sticky-session fashionned for the static one and round-robin fashionned for the dynamic one.

The setup script will use a list of IPs (space separated) to update the dynamic and static backend (upstream) of the Nginx configuration, allowing the user to define the configuration at runtime using the -e argument of the docker run command.

As we use the open source version of Nginx the sticky-cookies are not supported. We use the IP Hash algorithm alternative (ip_hash;). The Nginx server will create a Hash map with the client IP as a key and the backend selected as a value. Everytime a new request comes in, the nginx server will use the source ip to look in the hash table and redirect the query to the same backend everytime. We log the redirection to prove the correct behavior.

- Pros : No need to store anything on the client side
- Cons : client needs to send their queries with the same source IP everytime. (If their external access is also behind a load-balanced proxy this could cause some issues)

### Configuration	

##### Dockerfile

![](img/dockerfile.PNG)

1. We take the latest Nginx image from the Docker Hub
2. We update the package repository of our image operating system
3. We install vim to be able to debug the Nginx server
4. We copy the server configuration in the docker image of Nginx server
5. As we wanted to have an evolutive architecture, we copy specific sub-configuration that are included in the Nginx configuration
6. We copy the setup configuration for our server to the Nginx server
7. We upgrade read/write attributes on the setup script to be able to run it with docker
8. We are exposing our traffic to the default HTTP port, 80
9. We specify the entrypoint to docker with our setup script
10. We run our entrypoint (the setup script)

**Setup Nginx**

![](img/setup.PNG)

In this script, we are mapping the environment variables given in the command to run the docker on the variables inside our sub configuration for Nginx.

For each server ip (separated by space) given in both STATIC_BACKEND and DYNAMIC_BACKEND we generate a string containing a part of the Nginx configuration, then we use the **sed** command to update the upstream (sticky-session load-balancing for static and round-robin load-balancing for dynamic) section of Nginx configuration. 

Finally we start our server without deamons.

##### Nginx

###### nginx.conf

![](img/nginx.PNG)

- **events** : this statement is mandatory in the configuration. It is for setting the context of our server. Here we don't need any particular global options
- **http** : 
  - **include** : to be able to show all the MIME types encoding
  - **log_format** : to get logs in the windows where you run the container, we added the "$upstream_addr" to log to which server the query is redirected.
  - **access_log** : logs on the server
  - **include** : including all sub configurations

###### conf.d/default.conf

![](img/default.PNG)

- **listen** : server is listening to the port 80
- **upstream static_backend** : define an IPs cluster to which redirect the queries. It contains the IPs of our different static servers
  - **ip_hash** : define that the load balancing will be with sticky-session using the IP Hash algorithm
- **upstream dynamic_backend** : define an IPs cluster to which redirect the queries. It contains the IPs of our different dynamic servers
- **location /** : all request starting with **/** will get redirected to the static container
  - **STATIC_BACKEND** is a variable (list of servers with their ip) and gets mapped with the setup script 
- **location = /api/student/** & **location = /api/student** : all request that are stricly /api/student or /api/student/ will get redirected to the dynamic container
  - **DYNAMIC_BACKEND** is a variable (list of servers with their ip) and gets mapped with the setup script 

### Instructions to setup container

##### Build images

To setup the infrastructure  you first need to build the image of our static website :

```shell
docker build -t melmot/static static/ #if you're at the root of the project
```
Then you need to build our dynamic REST API :

```shell
docker build -t melmot/dynamic dynamic/ #if you're at the root of the project
```
And finally, you will need to build the dynamic reverse proxy image : 

```shell
docker build -t melmot/sticky_load_balancer dyn_reverse/ #if you're at the root of the project
```
##### Run containers

First, you need to run the static container without exposing the ports :

```
docker run melmot/static 
```

Second, you need to run the dynamic container without exposing the ports : 

```
docker run melmot/dynamic 
```

Finally, you need to run the dynamic reverse proxy container exposing the ports to be able to contact it and we will add two environment variables with the option **-e** : 

```
docker run -e DYNAMIC_BACKEND="%one_dynamic_app_ip%:%one_dynamic_app_port% ..." -e STATIC_APP="%one_static_app_ip%:%one_static_app_port% ..." --name sticky_load_balancer -p %your_local_port%:80 melmot/sticky_load_balancer
```

We already create a little script (**setup.sh**) at the root of the project to do the all the steps above, mapping the reverse proxy on the port **7777**.

### Accessing content

To access the static container content, you have to go to :

```
http://localhost:%your_local_port%/
```

and to access our dynamic container content, you have to go to : 

```
http://localhost:%your_local_port%/api/student
```
