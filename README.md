# Docker Container running multiple servers and a dynamic proxy with load-balancing to distribute the traffic and a cluster management

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

We configured the Nginx server for load-balancing between various static and dynamic backend, sticky-session fashionned.

The setup script will use a list of IPs (space separated) to update the dynamic and static backend (upstream) of the Nginx configuration, allowing the user to define the configuration at runtime using the -e argument of the docker run command.

As we use the open source version of Nginx the sticky-cookies are not supported. We use the IP Hash algorithm alternative (ip_hash;). The Nginx server will create a Hash map with the client IP as a key and the backend selected as a value. Everytime a new request comes in, the nginx server will use the source ip to look in the hash table and redirect the query to the same backend everytime. We log the redirection to prove the correct behavior.

- Pros : No need to store anything on the client side
- Cons : client needs to send their queries with the same source IP everytime. (If their external access is also behind a load-balanced proxy this could cause some issues)

Once started, the server will iteratively send GET requests to the IPs of the possible dynamic and static server. It'll update the Nginx configuration depending on the response.

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

```bash
#!/bin/bash

# Add setup for RES lab
echo "Setup for RES lab..."
echo "Static backend URLs : $STATIC_BACKEND"
echo "Dynamic backend URLs : $DYNAMIC_BACKEND"

# Creation of the backend and insertion in the nginx conf file
# Infinite loop - daemon mode like
while true
do
  static_backend=""
  # For each IP in STATIC_BACKEND
  for i in $STATIC_BACKEND
  do
  # We append the Nginx configuration line to our static_backend string
  static_backend="$static_backend\tserver $i weight=100 max_fails=5 fail_timeout=300;\n"
  done

  dynamic_backend=""
  # For each IP in DYNAMIC_BACKEND
  for i in $DYNAMIC_BACKEND
  do
  # We append the Nginx configuration line to our dynamic_backend string 
  dynamic_backend="$dynamic_backend\tserver $i weight=100 max_fails=5 fail_timeout=300;\n"
  done
  
  # We copy our Nginx configuration template containing the terms to replace with our dynamic_backend and static_backend strings
  cp /etc/nginx/conf.d/default.template /etc/nginx/conf.d/default.tmp
  # We replace the terms
  sed -i "s/STATIC_BACKEND/$static_backend/" /etc/nginx/conf.d/default.tmp
  sed -i "s/DYNAMIC_BACKEND/$dynamic_backend/" /etc/nginx/conf.d/default.tmp
  # We replace the Nginx configuration with the new one
  yes | cp -rf /etc/nginx/conf.d/default.tmp /etc/nginx/conf.d/default.conf
  rm -f /etc/nginx/conf.d/default.tmp

  # Reload NGINX
  nginx -s stop > /dev/null
  nginx > /var/nginx.log

  # Round ping to detect servers up and down
  # List of the IPs to scan
  pool="172.17.0.2 172.17.0.3 172.17.0.4 172.17.0.5 172.17.0.6 172.17.0.7 172.17.0.8 172.17.0.9 172.17.0.10 172.17.0.11 172.17.0.12 172.17.0.13 172.17.0.14 172.17.0.15 172.17.0.16 172.17.0.17 172.17.0.18 172.17.0.19 172.17.0.20"
  
  # Pour chaque IP a scan
  for ip in $pool
  do
    # On envoie une requete GET sur le port 80 et on stock le resultat dans reponse
    response=$(curl -s $ip --connect-timeout 0.1)
    # Si la reponse commence par <!D alors il s'agit de la balise <!Docstring ce qui veut dire qu'on backend static est derrière cette IP
    if [ "${response:0:3}" = "<!D" ];
    then
      # Si l'IP n'est pas encore dans notre configuration
      if [[ ${STATIC_BACKEND} != *"$ip"* ]];
      then
        # On l'ajoute
        STATIC_BACKEND="$STATIC_BACKEND $ip"
        echo "added static $STATIC_BACKEND"
      fi
    else
      # Sinon si rien ne se trouve derrière l'IP et que cette IP est dans notre configuration
      if [[ ${STATIC_BACKEND} == *"$ip"* ]];
      then
        # On l'enleve
        STATIC_BACKEND="${STATIC_BACKEND// $ip/}"
        echo "removed static $STATIC_BACKEND"
      fi
    fi
    # On envoie une requete GET sur le port 3000 et on stock le resultat dans reponse
    response=$(curl -s $ip:3000 --connect-timeout 0.1)
    # Si la reponse commence par le début d'un tableau JSON (vide ou non)
    if [ "${response:0:2}" = "[{" ] || [ "${response:0:2}" = "[]" ];
    then
      # Si l'IP n'est pas encore dans notre configuration
      if [[ ${DYNAMIC_BACKEND} != *"$ip"* ]];
      then
        # On l'ajoute
        DYNAMIC_BACKEND="$DYNAMIC_BACKEND $ip:3000"
        echo "added dynamic $DYNAMIC_BACKEND"
      fi
    else 
      # Sinon si rien ne se trouve derrière l'IP et que cette IP est dans notre configuration
      if [[ ${DYNAMIC_BACKEND} == *"$ip"* ]];
      then
        # On l'enleve
        DYNAMIC_BACKEND="${DYNAMIC_BACKEND//" $ip:3000"/}"
        echo "removed dynamic $DYNAMIC_BACKEND"
      fi
    fi
  done
done
```

Ideally, we'd have choose a more robust solution. Our initial idea was to program the static and dynamic docker containers to send an UDP datagram to a listener on the Nginx reverse proxy in order to notify it if one goes up or down. After having received the UDP datagram, the Nginx configuration would have been updated accordingly. Unfortunately we had to rush through the last part of this laboratory, and we chose a solution effective and quickly implemented.

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
  - **ip_hash** : define that the load balancing will be with sticky-session
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
And finally, you will need to build the cluster manager/dynamic reverse proxy/load balancer image : 

```shell
docker build -t melmot/cluster dyn_reverse/ #if you're at the root of the project
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

Finally, you need to run the cluster manager/dynamic reverse proxy/load balancer container exposing the ports to be able to contact it and we will add two environment variables with the option **-e** : 

```
docker run -e DYNAMIC_BACKEND="%one_dynamic_app_ip%:%one_dynamic_app_port% ..." -e STATIC_APP="%one_static_app_ip%:%one_static_app_port% ..." --name cluster -p %your_local_port%:80 melmot/cluster
```

We already create a little script (**setup.sh**) at the root of the project to do the all the steps above, mapping the reverse proxy on the port **8888**.

### Accessing content

To access the static container content, you have to go to :

```
http://localhost:%your_local_port%/
```

and to access our dynamic container content, you have to go to : 

```
http://localhost:%your_local_port%/api/student
```
