#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Missing parameters; $1 - site name ]"
  exit 1
fi

service rabbitmq-server start
service apache2 start
service celery-monitor start
service celery start

tail -f /dev/null