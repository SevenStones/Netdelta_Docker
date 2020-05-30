#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Missing parameters; $1 - site name ]"
  exit 1
fi

VENV_ROOT="/srv/netdelta304"
SITE_ROOT="/srv"
LOG_ROOT=${SITE_ROOT}/logs/$1

#echo "Adjusting mysql filesystem permissions"
#chown -R mysql:mysql /var/lib/mysql
#echo "sleeping 20"
#sleep 20
#service mysql start

service rabbitmq-server start
service apache2 start
service celery-monitor start

cd /srv/netdelta

su -m iantibble -c "${VENV_ROOT}/bin/celery worker -E -A nd -n $1 -Q $1 --loglevel=info -B --logfile=${SITE_ROOT}/logs/$1/celery.log"

tail -f /dev/null