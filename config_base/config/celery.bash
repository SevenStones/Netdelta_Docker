#!/usr/bin/env bash

SITE_ROOT="/srv"
NETDELTA_ROOT="${SITE_ROOT}/netdelta"
VIRTUALENV_DIR="${SITE_ROOT}/netdelta304"
PROC_FINDER="${VIRTUALENV_DIR}/bin/celery worker"
PROG="${VIRTUALENV_DIR}/bin/celery"
RETVAL=0
PROGNAME="Celery"
X=""
LOGS_ROOT="${SITE_ROOT}/logs"

if [ ! -f "$PROG" ]; then
  echo "Celery not found"
  exit 1
fi

if [ ! -d "${VIRTUALENV_DIR}" ]; then
  echo "Virtualenv not found at specified location"
  exit 1
fi

if [ ! -d "${NETDELTA_ROOT}" ]; then
  echo "Netdelta root directory not found"
  exit 1
fi

if [ ! -d "${LOGS_ROOT}" ]; then
  echo "Logs root directory not found"
  exit 1
fi

is_running() {
  X=$(pgrep -f "${PROC_FINDER}")
  echo $X
}

start() {

  Z=$(is_running)
  if [ "$Z" != "" ]; then
    echo "Celery is already active"
    exit 0
  fi

  cd ${NETDELTA_ROOT} || (echo "Netdelta root directory not found; exit 1;")

  su -m iantibble -c "${PROG} worker -E -A nd -n SITE -Q SITE --loglevel=info -B --logfile=${LOGS_ROOT}/SITE/celery.log 1>/dev/null&"
  Z=$(is_running)
  if [ "$Z" != "" ]; then
    echo -e "Celery worker launched successfully : [${GREEN}OK${NC}]"
    exit 0
  else
    echo "Celery worker launch failed"
    exit 1
  fi
}

stop() {

  Z=$(is_running)

  if [ "$Z" != "" ]; then
    kill -9 $Z
    if [ "$?" -eq 0 ]; then
      echo -e "${PROGNAME} shutdown successful: [${GREEN}OK${NC}]"
    else
      echo "${PROGNAME} shutdown failed"
      exit 1
    fi
  else
    echo "${PROGNAME} is not active"
  fi
}

status() {

  Z=$(is_running)

  if [ "$Z" != "" ]; then
    echo -e "${PROGNAME} is active"
    exit 0
  else
    echo "${PROGNAME} is not active"
    exit 0
  fi
}

# See how we were called.
case "$1" in
start)
  start
  ;;
stop)
  stop
  exit 0
  ;;
status)
  status
  ;;
restart)
  stop
  start
  ;;
*)
  echo $"Usage: $PROGNAME {start|stop|restart|status}"
  exit 1
  ;;
esac
