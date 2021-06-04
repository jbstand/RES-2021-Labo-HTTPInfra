#!/bin/bash

# Add setup for RES lab
echo "Setup for RES lab..."
echo "Static app URL : $STATIC_APP"
echo "Dynamic app URL : $DYNAMIC_APP"
sed -i "s/STATIC_URL/$STATIC_APP/" /etc/nginx/conf.d/default.conf
sed -i "s/DYNAMIC_URL/$DYNAMIC_APP/" /etc/nginx/conf.d/default.conf

# Start NGINX
nginx -g "daemon off;"