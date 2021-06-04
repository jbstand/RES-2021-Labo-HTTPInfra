#Building images
docker build -t melmot/static static/
docker build -t melmot/dynamic dynamic/
docker build -t melmot/reverse reverse/

#Running containers
docker run melmot/static 
docker run melmot/dynamic 
docker run -p 3333:80 melmot/reverse 