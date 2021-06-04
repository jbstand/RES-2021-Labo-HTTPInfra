# Docker Container running a dynamic HTTP server
- ## Docker Container running a dynamic HTTP server
    + [Description](#description)
    + [Configuration](#configuration)
        * [Dockerfile](#dockerfile)
    + [Instructions to setup container](#instructions-to-setup-container)
    + [Accessing content](#accessing-content)

### Description

This docker image based on [Node](https://hub.docker.com/_/node) contains a dynamic REST HTTP API served by Node. The server has only one endpoint : **/**. The port exposed is the default expressjs which is 3000.

The endpoint **/** returns an array of JSON objects :
{
    'animal': "name of the animal",
    'gender': "Male | Female",
    'profession': "profession of the animal"
}

### Configuration

##### Dockerfile

![](img/dockerfile.PNG)

1. We take the latest Node image from the Docker Hub
2. We copy the src folder (containing the sources) to the folder of our choice (*/usr/share/js*)
3. We update the package repository of our image operating system
5. We install vim to be able to debug the node server
5. We specify the directory where we want to work and execute our instructions
6. We install all the dependencies for our javascript application
7. We are exposing our traffic to the default express js port, 3000
8. We run the node server with our javascript application

### Instructions to setup container

To setup the container, you first need to build the image :

```shell
docker build -t melmot/dynamic dynamic/ #if you're at the root of the project
```

Then you can run the built image :

```
docker run -p %your_local_port%:3000 melmot/dynamic 
```

We already create a little script (**setup.sh**) at the root of the project to do the two step above, mapping on the port **1111**.

### Accessing content

To access the webpage, you can go to :

```
http://localhost:%your_local_port%/
```

