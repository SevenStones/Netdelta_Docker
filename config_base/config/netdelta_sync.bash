#!/usr/bin/env bash
# This script syncs the code base under /srv/staging to container live code base under /srv/netdelta
# Ian Tibble - 10 June 2020
#
#  usage: docker exec -d netdelta_<site_name> sh -c '/srv/config_base/config/netdelta_sync.bash'
# (this script is deployed in containers)
#

ROOT="/srv"
STAGING_ROOT="${ROOT}/staging/"
NETDELTA_ROOT="${ROOT}/netdelta"
CONFIG_ROOT="${ROOT}/config_base/config"
EXCLUDE_FILE="${CONFIG_ROOT}/sync-excludes.txt"
LOG_FILE="/var/log/netdelta_code_sync.log"

echo "settings.py and wsgi.py will not be synced"

rsync -avzrl --progress --exclude-from $EXCLUDE_FILE --progress ${STAGING_ROOT}/netdelta/ ${NETDELTA_ROOT}/ | tee ${LOG_FILE}

service apache2 restart