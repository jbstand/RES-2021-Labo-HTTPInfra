#!/bin/bash

#Building images
docker build -t melmot/static static/
docker build -t melmot/dynamic dynamic/
docker build -t melmot/dyn_reverse dyn_reverse/

#Running images
docker run melmot/static 
docker run melmot/dynamic 
docker run -e DYNAMIC_APP=172.17.0.3:3000 -e STATIC_APP=172.17.0.2 --name dyn_reverse -p 5555:80 melmot/dyn_reverse