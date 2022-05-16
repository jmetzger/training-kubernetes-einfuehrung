# Registry local with microk8s 

## Installation 

```
# node 1 - aktivieren 
microk8s enable registry 


```

## Creating an image mit docker 

```
# node 1 / nicht client 
snap install docker 

mkdir myubuntu 
cd myubuntu 
# vi Dockerfile 
FROM ubuntu:latest
RUN apt-get update; apt-get install -y inetutils-ping
CMD ["/bin/bash"]


docker build -t localhost:32000/myubuntu .
docker images 
docker push localhost:32000/myubuntu 

```
