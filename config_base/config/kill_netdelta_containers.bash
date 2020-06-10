#!/usr/bin/env bash

if [ "$1" == "-h" ]; then
  echo "usage: kill_nd_containers.bash [rm]"
  exit 0
fi

[ "$1" != "rm" ] && [ $1 != "-h" ] && (echo "usage: kill_nd_containers.bash [rm]"; exit 1)

DOCKER_ROOT="/home/iantibble/netdd"
SITES_FILE="${DOCKER_ROOT}/config_base/config/SITES"

[ ! -f ${SITES_FILE} ] && (echo "SITES file not found"; exit 1)

while read c; do
  if [ $1 == "rm" ]; then
    docker stop netdelta_$c
    docker rm netdelta_$c
  else
    docker stop netdelta_$c
  fi
done < ${SITES_FILE}
