#!/bin/bash

# Add setup for RES lab
echo "Setup for RES lab..."
echo "Static backend URLs : $STATIC_BACKEND"
echo "Dynamic backend URLs : $DYNAMIC_BACKEND"

# Creation of the backend and insertion in the nginx conf file
static_backend=""

for i in $STATIC_BACKEND
do 
static_backend="$static_backend\t\tserver $i;\n"
done

dynamic_backend=""

for i in $DYNAMIC_BACKEND
do 
dynamic_backend="$dynamic_backend\t\tserver $i;\n"
done

sed -i "s/STATIC_URL/$STATIC_APP/" /etc/nginx/conf.d/default.conf
sed -i "s/DYNAMIC_URL/$DYNAMIC_APP/" /etc/nginx/conf.d/default.conf

# Start NGINX
nginx -g "daemon off;"