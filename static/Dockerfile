FROM nginx
COPY src /usr/share/nginx/html
COPY conf/nginx.conf /etc/nginx/nginx.conf
# For testing and debugging, better than native cat
RUN apt-get update && \
    apt-get install -y vim

EXPOSE 80