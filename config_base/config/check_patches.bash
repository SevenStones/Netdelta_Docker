#!/usr/bin/env bash

# Ian Tibble - 17 April 2020

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [ "$#" -gt 2 ]; then
  echo "Usage: check_patches.bash venv [-c]"
  exit 1
fi
if [ "$#" -eq 0 ]; then
  echo "Usage: check_patches.bash venv [-c]"
  exit 1
fi

if [ "$1" == "-h" ]; then
  echo "Usage: check_patches.bash venv [-c]"
  exit 0
fi

CONFIG_ROOT="/srv/config_base/config"
VENV_ROOT="/srv/netdelta_venv"
MYSQL_DIR="${VENV_ROOT}/lib/python3.6/site-packages/django/db/backends/mysql"
LIBNMAP_DIR="${VENV_ROOT}/lib/python3.6/site-packages/libnmap"
PATCH_DIR="${CONFIG_ROOT}/patches"
if [ ! -d "${VENV_ROOT}" ]; then
  echo "Specified Virtualenv does not exist"
  exit 1
fi

if [ "$#" -eq 2 ] && [ "$2" != "-c" ]; then
  echo "Unknown option: $2"
  echo "Usage: check_patches.bash venv [-c]"
  exit 1
fi

function patch_MySQL_base {

  if [ "$1" == "-c" ]; then
    echo -e "${MYSQL_DIR}/base.py: [${RED}NOT PATCHED${NC}]"
    return
  fi

  echo "Applying patch for base.py (MySQL Django framework)"
  cp -v ${MYSQL_DIR}/base.py ${MYSQL_DIR}/base.orig
  patch ${MYSQL_DIR}/base.py -i ${PATCH_DIR}/base.patch \
    -o ${MYSQL_DIR}/base.patched
  if [ "$?" == 0 ]; then
    echo -e "Successfully patched base.py file: [${GREEN}OK${NC}]"
    cp -v ${MYSQL_DIR}/base.patched ${MYSQL_DIR}/base.py
    rm ${MYSQL_DIR}/base.patched
    echo "backup of original file is at ${MYSQL_DIR}/base.orig"
  else
    echo "Patching of Django MySQL base.py failed"
    exit 1
  fi
}

function patch_libnmap(){

  if [ "$1" == "-c" ]; then
    echo -e "${LIBNMAP_DIR}/process.py: [${RED}NOT PATCHED${NC}]"
    return
  fi

  echo "Applying patch for libnmap"
  cp -v ${LIBNMAP_DIR}/process.py ${LIBNMAP_DIR}/process.orig
  patch ${LIBNMAP_DIR}/process.py -i ${PATCH_DIR}/libnmap-process.patch \
    -o ${LIBNMAP_DIR}/process.patched
  if [ "$?" == 0 ]; then
    echo -e "Successfully patched libnmap process.py: [${GREEN}OK${NC}]"
    cp -v ${LIBNMAP_DIR}/process.patched ${LIBNMAP_DIR}/process.py
    rm -v ${LIBNMAP_DIR}/process.patched
    echo "backup of original file is at ${LIBNMAP_DIR}/process.orig"
  else
    echo "Patching of libnmap process.py failed"
    exit 1
  fi
}

cmp ${PATCH_DIR}/base.py.modified ${MYSQL_DIR}/base.py >/dev/null &&
  echo -e "Django MySQL base.py already patched: [${GREEN}OK${NC}]" ||
  patch_MySQL_base "$2"

cmp ${PATCH_DIR}/process.py.modified ${LIBNMAP_DIR}/process.py >/dev/null &&
  echo -e "libnmap process.py already patched: [${GREEN}OK${NC}]" ||
  patch_libnmap "$2"
echo
