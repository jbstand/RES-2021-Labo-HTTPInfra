FROM nginx

# For testing and debugging, better than native cat
RUN apt-get update && \
    apt-get install -y vim

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/conf.d /etc/nginx/conf.d
COPY setup.sh /usr/local/bin/

EXPOSE 80

ENTRYPOINT ["setup.sh"]
CMD ["run"]