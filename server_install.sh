#!/bin/bash

apt update
apt install -y \
  docker.io \
  curl \
  vim \
  wget \
  tree \
  htop

# here we would install docker-compose
# and then make the containers start
