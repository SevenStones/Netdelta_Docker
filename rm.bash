#!/usr/bin/env bash

for i in `docker ps -a | grep -v IMAGE | grep -v grep | awk '{print $1}'`
do
docker rm $i
done
