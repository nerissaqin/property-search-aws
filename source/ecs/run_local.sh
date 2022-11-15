#!/bin/sh
docker build -t realestate-admin:latest ./docker
docker rm -f realestate-admin
docker run --rm --name realestate-admin -it -p 80:80 realestate-admin:latest