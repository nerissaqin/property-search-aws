#!/bin/sh
docker build -t suburb:latest ./docker
docker rm -f suburb
docker run --rm --name suburb -it -p 3000:3000 suburb:latest