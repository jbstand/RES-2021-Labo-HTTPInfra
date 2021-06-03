FROM nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/conf.d /etc/nginx/conf.d

# For testing and debugging, better than native cat
RUN apt-get update && \
    apt-get install -y vim

EXPOSE 80