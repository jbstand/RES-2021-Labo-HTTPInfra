#!/bin/bash

# Add setup for RES lab
echo "Setup for RES lab..."
echo "Static backend URLs : $STATIC_BACKEND"
echo "Dynamic backend URLs : $DYNAMIC_BACKEND"

# Creation of the init config file
static_backend=""

for i in $STATIC_BACKEND
do
    static_backend="$static_backend\tserver $i weight=100 max_fails=5 fail_timeout=300;\n"
done

dynamic_backend=""

for i in $DYNAMIC_BACKEND
do
    dynamic_backend="$dynamic_backend\tserver $i weight=100 max_fails=5 fail_timeout=300;\n"
done

sed -i "s/STATIC_BACKEND/$static_backend/" /etc/nginx/conf.d/default.conf
sed -i "s/DYNAMIC_BACKEND/$dynamic_backend/" /etc/nginx/conf.d/default.conf

# Start Nginx
reload=true
nginx > /var/nginx.log
# Creation of the backend and update of the nginx conf file
while true
do
  static_backend=""

  for i in $STATIC_BACKEND
  do
  static_backend="$static_backend\tserver $i weight=100 max_fails=5 fail_timeout=300;\n"
  done

  dynamic_backend=""

  for i in $DYNAMIC_BACKEND
  do
  dynamic_backend="$dynamic_backend\tserver $i weight=100 max_fails=5 fail_timeout=300;\n"
  done

  cp /etc/nginx/conf.d/default.template /etc/nginx/conf.d/default.tmp
  sed -i "s/STATIC_BACKEND/$static_backend/" /etc/nginx/conf.d/default.tmp
  sed -i "s/DYNAMIC_BACKEND/$dynamic_backend/" /etc/nginx/conf.d/default.tmp
  yes | cp -rf /etc/nginx/conf.d/default.tmp /etc/nginx/conf.d/default.conf
  rm -f /etc/nginx/conf.d/default.tmp

  # Reload NGINX
  if [ $reload == true ];
  then
    nginx -s reload > /dev/null
    reload=false
  fi
  # Round ping to detect servers up and down 
  pool="172.17.0.2 172.17.0.3 172.17.0.4 172.17.0.5 172.17.0.6 172.17.0.7 172.17.0.8 172.17.0.9 172.17.0.10 172.17.0.11 172.17.0.12 172.17.0.13 172.17.0.14 172.17.0.15 172.17.0.16 172.17.0.17 172.17.0.18 172.17.0.19 172.17.0.20"
  for ip in $pool
  do
    # If the IP is not the same as the host
    if [ "$ip" != "$(awk 'END{print $1}' /etc/hosts)" ];
    then
      response=$(curl -s $ip --connect-timeout 0.1) 
      if [ "${response:0:3}" = "<!D" ];
      then
        if [[ ${STATIC_BACKEND} != *"$ip"* ]];
        then
          reload=true
          STATIC_BACKEND="$STATIC_BACKEND $ip"
          echo "added static $STATIC_BACKEND"
        fi
      else
        if [[ ${STATIC_BACKEND} == *"$ip"* ]];
        then
          reload=true
          STATIC_BACKEND="${STATIC_BACKEND//" $ip"/}"
          # To remove the ip even if it doesn't start with a space (first IP of the list)
          STATIC_BACKEND="${STATIC_BACKEND//"$ip"/}"
          echo "removed static $STATIC_BACKEND"
        fi
      fi
      response=$(curl -s $ip:3000 --connect-timeout 0.1)
      if [ "${response:0:2}" = "[{" ] || [ "${response:0:2}" = "[]" ];
      then
        if [[ ${DYNAMIC_BACKEND} != *"$ip"* ]];
        then
          reload=true
          DYNAMIC_BACKEND="$DYNAMIC_BACKEND $ip:3000"
          echo "added dynamic $DYNAMIC_BACKEND"
        fi
      else 
        if [[ ${DYNAMIC_BACKEND} == *"$ip"* ]];
        then
          reload=true
          DYNAMIC_BACKEND="${DYNAMIC_BACKEND//" $ip:3000"/}"
          # To remove the ip even if it doesn't start with a space (first IP of the list)
          DYNAMIC_BACKEND="${DYNAMIC_BACKEND//"$ip:3000"/}"
          echo "removed dynamic $DYNAMIC_BACKEND"
        fi
      fi
    fi
  done
done
