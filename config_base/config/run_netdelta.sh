#!/bin/bash
VENV_ROOT="/srv/netdelta304"
SITE_ROOT="/srv"

service mysql start
service rabbitmq-server start

cd /srv/netdelta

service apache2 start

su -m iantibble -c "${VENV_ROOT}/bin/celery worker -E -A nd -n $1 -Q $1 --loglevel=info -B --logfile=${SITE_ROOT}/netdelta/logs/celery.log"
