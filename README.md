# Docker Container running a static HTTP server

### Description

This docker image based on [Nginx](https://github.com/nginxinc/docker-nginx) contains a static HTTP website served by Nginx. The port exposed is the default HTTP one, 80.

### Instructions to setup container

To setup the container, you first need to build the image :

```shell
docker build -t melmot/static static/ #if you're at the root of the project
```

Then you can run the built image :

```
docker run -p %your_local_port%:80 melmot/static 
```

We already create a little script (**setup.sh**) at the root of the project to do the two step above, mapping on the port **5555**.

### Accessing content

To access the webpage, you can go to :

```
http://localhost:%your_local_port%/
```

