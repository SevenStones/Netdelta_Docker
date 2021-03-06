#!/usr/bin/env bash
NC='\033[0m' # No Color
GREEN='\033[0;32m'
SITE_ROOT="/srv"
PROG="${SITE_ROOT}/netdelta/celery-monitor.py"
VIRTUALENV_DIR="/srv/netdelta_venv"
PIDFILE=/tmp/celery-monitor.pid
RETVAL=0
PROGNAME="Celery monitor"
X=""

if [ ! -f "$PROG" ]; then
  echo "Monitoring script not found"
  exit 1
fi

if [ ! -d "$VIRTUALENV_DIR" ]; then
  echo "Virtualenv not found at specified location"
  exit 1
fi

if [ ! -f "$VIRTUALENV_DIR/bin/python3" ]; then
  echo "Python not found in specified virtualenv"
  exit 1
fi

is_running() {
  X=$(pgrep -f "${VIRTUALENV_DIR}/bin/python3 ${PROG}")
  echo $X
}

start() {

  Z=$(is_running)
  if [ "$Z" != "" ]; then
    echo "Celery is already active"
    exit 0
  fi

  su -m iantibble -c "${VIRTUALENV_DIR}/bin/python3 $PROG &"
  Z=$(is_running)
  if [ "$Z" != "" ]; then
    echo -e "Celery monitoring service launched successfully : [${GREEN}OK${NC}]"
    exit 0
  else
    echo "Celery monitoring service launch failed"
    exit 1
  fi
}

stop (){

  Z=$(is_running)

  if [ "$Z" != "" ]; then
    kill -9 $Z
    if [ "$?" -eq 0 ]; then
      echo -e "Celery-monitor shutdown successful: [${GREEN}OK${NC}]"
    else
      echo "${PROGNAME} shutdown failed"
      exit 1
    fi
  else
    echo "Celery-monitor is not active"
  fi
}

status(){

  Z=$(is_running)

  if [ "$Z" != "" ]; then
    echo -e "Celery-monitor is active"
    exit 0
  else
    echo "Celery-monitor is not active"
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
esac