# Docker Container running multiple servers and a dynamic proxy with load-balancing to distribute the traffic.

Nginx default load-balancing -> round-robin

docker run -e DYNAMIC_BACKEND="172.17.0.5:3000 172.17.0.6:3000" -e STATIC_BACKEND="172.17.0.2 172.17.0.3" --name melmot_loadbalancing -p 5555:80 melmot/loadbalancing

Fill report here plzplz