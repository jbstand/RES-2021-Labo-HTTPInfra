#!/bin/bash

#Building images
docker build -t melmot/static static/
docker build -t melmot/dynamic dynamic/
docker build -t melmot/load_balancer dyn_reverse/ 

#Running images
docker run melmot/static 
docker run melmot/static 
docker run melmot/dynamic 
docker run melmot/dynamic 
docker run -e DYNAMIC_BACKEND="172.17.0.5:3000 172.17.0.4:3000" -e STATIC_BACKEND="172.17.0.2 172.17.0.3" --name load_balancer -p 4444:80 melmot/load_balancer