#!/usr/bin/env bash

if [ "$1" == "-h" ]; then
  echo "usage: site_deploy.bash site port [le]"
  exit 0
fi

if [ "$#" -lt 2 ]; then
  echo "Missing parameters; $1 - site name; $2 - port; [$3 - le ]"
  exit 1
fi



DOCKER_DIR="/home/iantibble/netdd"
CERTS_DIR="${DOCKER_DIR}"/config_base/config/certs
NC='\033[0m' # No Color
GREEN='\033[0;32m'
RUN_LOG_FILE="/tmp/docker-build.log"

[ -d "${CERTS_DIR}" ] || (echo "certs directory ${CERTS_DIR} not found"; exit 1;)

[ "$3" == "le" ] && [ "$(ls -A ${CERTS_DIR})" ] || (echo "No certs found in ${CERTS_DIR}"; exit 1;)
echo "Make sure mysql is shut down on the host first, and you have the correct Letsencrypt certs"

[ ! "$(docker ps -q -f name=mysql_netdelta)" ] && (echo "your mysql container ain't active - quitting"; exit 1;)

cd ${DOCKER_DIR} || (echo "Dockerfile not found, directory does not exist"; exit 1;)

echo "initial build"
docker build -t netdelta/$1:core --build-arg SITE=$1 --build-arg PORT=$2 . 1>> ${RUN_LOG_FILE}
if [ "$?" == 0 ]; then
  echo -e "docker build of netdelta/$1:core image reported no errors: [${GREEN}OK${NC}]"
  docker images
  echo
else
  echo "docker build of netdelta/$1:core image failed"
fi

if [ "$3" == "le" ]; then
  docker run -it -p $2:$2 --name netdelta_$1 --network netdelta_net -v netdelta_app:/srv/netdelta -v \
netdelta_logs:/srv/logs netdelta/$1:core $1 $2 le 1>> ${RUN_LOG_FILE}
else
  docker run -it -p $2:$2 --name netdelta_$1 --network netdelta_net -v netdelta_app:/srv/netdelta -v \
netdelta_logs:/srv/logs netdelta/$1:core $1 $2 1>> ${RUN_LOG_FILE}
fi
wait
if [ "$?" == 0 ]; then
  echo -e "docker run of netdelta/$1:core image reported no errors: [${GREEN}OK${NC}]"
  docker ps -a
  echo
else
  echo "docker run of netdelta/$1:core image failed"
fi

echo "docker commit to generate netdelta/$1:actual image"
docker commit --change='ENTRYPOINT ["/srv/staging/config/run_netdelta.sh"]' netdelta_$1 netdelta/$1:actual 1>> ${RUN_LOG_FILE}

if [ "$?" == 0 ]; then
  echo -e "docker commit of netdelta/$1:core image reported no errors: [${GREEN}OK${NC}]"
  docker images
  echo
else
  echo "docker commit of netdelta/$1:core image failed"
fi

echo "docker stop netdelta_$1"
docker stop netdelta_$1 1>/dev/null

echo "docker rm netdelta_$1"
docker rm netdelta_$1 1>/dev/null

echo "final run"
docker run -itd -p $2:$2 --network netdelta_net --name netdelta_$1 -v netdelta_app:/srv/netdelta \
-v netdelta_logs:/srv/logs netdelta/$1:actual $1 1>> ${RUN_LOG_FILE}
wait
if [ "$?" == 0 ]; then
  echo -e "docker run of netdelta/$1:actual image reported no errors: [${GREEN}OK${NC}]"
  docker ps -a
  echo
else
  echo "docker run of netdelta/$1:actual image failed"
fi
