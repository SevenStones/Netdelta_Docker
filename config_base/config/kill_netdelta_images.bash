#!/usr/bin/env bash

if [ "$1" == "-h" ]; then
  echo "usage: kill_nd_images.bash"
  exit 0
fi

DOCKER_ROOT="/home/iantibble/netdd"
SITES_FILE="${DOCKER_ROOT}/config_base/config/SITES"

[ ! -f ${SITES_FILE} ] && (echo "SITES file not found"; exit 1)

while read c; do
  echo "Nuking $c images"
  docker rmi netdelta/$c:actual
  docker rmi netdelta/$c:core
done < ${SITES_FILE}
