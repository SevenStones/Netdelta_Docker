#!/usr/bin/env bash

for i in `docker images | grep -v REPOSITORY | grep -v grep | awk '{print $3}'`
do
docker rmi $i
done
