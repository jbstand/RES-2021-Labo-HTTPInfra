# Docker Container running a reverse proxy with nodes IP taken from env variables

docker run -e DYNAMIC_APP=172.17.0.3:3000 -e STATIC_APP=172.17.0.2 --name melmot_dynreverse -p 5555:80 melmot/dynreverse

Fill report here plzplz