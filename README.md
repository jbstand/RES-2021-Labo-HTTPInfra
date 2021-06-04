# Docker Container running multiple servers and a dynamic proxy with load-balancing to distribute the traffic.

Nginx default load-balancing -> round-robin

docker run -e DYNAMIC_BACKEND="172.17.0.5:3000 172.17.0.6:3000" -e STATIC_BACKEND="172.17.0.2 172.17.0.3" --name melmot_sticky -p 5555:80 melmot/sticky

Fill report here plzplz


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
    # echo "Comparing ${response:0:2}"
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

Comments inline
