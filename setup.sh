docker build -t melmot/static static/

docker run -p 5555:80 melmot/static 