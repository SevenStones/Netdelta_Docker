#!/usr/bin/env bash

if [ "$1" == "-h" ]; then
  echo "usage: site_deploy.bash site port [le] [certs]"
  exit 0
fi

if [ "$#" -lt 2 ]; then
  echo "Missing parameters; $1 - site name; $2 - port; [$3 - le ]; [$4 - certs]"
  exit 1
fi

[ "$#" -gt 4 ] && { echo "Invalid options: usage - site_deploy.sh site port [le] [certs]"; exit 1; }
[[ "$#" -eq 3 ]] && [ "$3" != "le" ] && { echo "Invalid options: usage - site_deploy.sh site port [le] [certs]"; exit 1; }
[[ "$#" -eq 4 ]] && [ "$4" != "certs" ] && { echo "hello. Invalid options: usage - site_deploy.sh site port [le] [certs]"; exit 1; }

DOCKER_DIR="/home/iantibble/netdd"
CERTS_DIR="${DOCKER_DIR}"/config_base/config/certs
NC='\033[0m' # No Color
GREEN='\033[0;32m'
RUN_LOG_FILE="/tmp/docker-build.log"
DATABASE_CONTAINER="mysql_netdelta"
FILESERVER="file_server"

[ -d "${CERTS_DIR}" ] || (echo "certs directory ${CERTS_DIR} not found"; exit 1;)

[ "$4" == "certs" ] && [ "$(ls -A ${CERTS_DIR})" ] || { echo "No certs found in ${CERTS_DIR}"; exit 1; }

echo "Make sure mysql is shut down on the host first, and you have the correct Letsencrypt certs"

[ "$(docker inspect -f '{{.State.Running}}' $DATABASE_CONTAINER)" == "true" ] || { echo "your mysql container ain't active - quitting"; exit 1; }
[ "$(docker inspect -f '{{.State.Running}}' $FILESERVER)" == "true" ] || { echo "your fileserver container ain't active - quitting"; exit 1; }

cd ${DOCKER_DIR} || { echo "Dockerfile not found, directory does not exist"; exit 1; }

echo "initial build"
docker build -t netdelta/$1:core --build-arg SITE=$1 --build-arg PORT=$2 . 1>> ${RUN_LOG_FILE}
if [ "$(docker images -q netdelta/$1:core)" ]; then
  echo -e "docker build of netdelta/$1:core image reported no errors: [${GREEN}OK${NC}]"
  docker images
  echo
else
  echo "docker build of netdelta/$1:core image failed"
  exit 1
fi

case "$#" in
  4)
    [ "$3" == "le" ] && [ "$4" == "certs" ] || { echo "Invalid options: usage - site_deploy.sh site port [le] [certs]"; exit 1; }
    docker run -it -p $2:$2 --name netdelta_$1 --network netdelta_net -v netdelta_app:/srv/staging -v \
    netdelta_logs:/srv/logs -v le:/etc/letsencrypt -v data:/data -v netdelta_venv:/srv/netdelta_venv \
    netdelta/$1:core $1 $2 le certs 1>> ${RUN_LOG_FILE}
    ;;
  3)
    [ "$3" == "le" ] || { echo "Invalid options: usage - site_deploy.sh site port [le] [certs]"; exit 1; }
    docker run -it -p $2:$2 --name netdelta_$1 --network netdelta_net -v netdelta_app:/srv/staging -v \
    netdelta_logs:/srv/logs -v le:/etc/letsencrypt -v data:/data -v netdelta_venv:/srv/netdelta_venv \
    netdelta/$1:core $1 $2 le 1>> ${RUN_LOG_FILE}
    ;;
  2)
    docker run -it -p $2:$2 --name netdelta_$1 --network netdelta_net -v netdelta_app:/srv/staging -v \
    netdelta_logs:/srv/logs -v le:/etc/letsencrypt -v data:/data -v netdelta_venv:/srv/netdelta_venv \
    netdelta/$1:core $1 $2 1>> ${RUN_LOG_FILE}
    ;;
  *)
    { echo "Invalid options: usage - site_deploy.sh site port [le] [certs]"; exit 1; }
esac

echo "sleeping 10"
sleep 10
if [ "$(docker ps -a | grep -w netdelta_$1'$' | grep -v grep)" ]; then
  echo -e "docker run of netdelta/$1:core image reported no errors: [${GREEN}OK${NC}]"
  docker ps -a
  echo
else
  echo "docker run of netdelta/$1:core image failed"
  exit 1
fi

echo "docker commit to generate netdelta/$1:actual image"
docker commit --change='ENTRYPOINT ["/srv/config_base/config/run_netdelta.sh"]' netdelta_$1 netdelta/$1:actual 1>> ${RUN_LOG_FILE}

if [ "$(docker images -q netdelta/$1:actual)" ]; then
  echo -e "docker commit of netdelta/$1:core image reported no errors: [${GREEN}OK${NC}]"
  docker images
  echo
else
  echo "docker commit of netdelta/$1:core image failed"
  exit
fi

echo "docker stop netdelta_$1"
docker stop netdelta_$1 1>/dev/null

echo "docker rm netdelta_$1"
docker rm netdelta_$1 1>/dev/null

echo "final run"
docker run -itd -p $2:$2 --name netdelta_$1 --network netdelta_net -v netdelta_app:/srv/staging -v \
netdelta_logs:/srv/logs -v data:/data -v le:/etc/letsencrypt -v netdelta_venv:/srv/netdelta_venv netdelta/$1:actual $1 1>> ${RUN_LOG_FILE}
echo "sleeping 10"
sleep 10
if [ "$(docker ps -a | grep -w netdelta_$1'$' | grep -v grep)" ]; then
  echo -e "docker run of netdelta/$1:actual image reported no errors: [${GREEN}OK${NC}]"
  docker ps -a
  echo
else
  echo "docker run of netdelta/$1:actual image failed"
fi
