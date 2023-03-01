# Dockerfile design for a small images 

  * Delete all files that are not needed in image 

## Example 

```
## Delete files needed for installation
## Right after the installation of the necessary 
# Variante 2
# nano Dockerfile
FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y inetutils-ping && \
    rm -rf /var/lib/apt/lists/*
# CMD ["/bin/bash"]

```

## Example 2: Start from scratch 

 * https://codeburst.io/docker-from-scratch-2a84552470c8

