#building images
docker build -t melmot/static static/
docker build -t melmot/dynamic dynamic/
docker build -t melmot/reverse reverse/

#running containers
docker run melmot/static
docker run melmot/dynamic
docker run -p 2222:80 melmot/reverse
