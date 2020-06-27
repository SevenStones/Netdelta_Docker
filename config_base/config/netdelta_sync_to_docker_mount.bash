#!/usr/bin/env bash
# for syncing netdelta test code base under /home/iantibble/netdd/vol_server/nd_base/netdelta to
# to the docker volume mount for /srv/staging/netdelta under /var/lib/docker/volumes/netdelta_app/_data/netdelta
# (on the docker host). Must be done as root.
#
# Ian Tibble - 27 June 2020

BASE_DIR="/home/iantibble"
DOCKER_BASE="${BASE_DIR}/netdd"
NETDELTA_CODEBASE_ROOT="${DOCKER_BASE}/vol_server/nd_base/netdelta"
NETDELTA_DOCKER_VOL_ROOT="/var/lib/docker/volumes/netdelta_app/_data/netdelta"

EXCLUDE_FILE="${DOCKER_BASE}/config_base/config/sync-excludes.txt"

if [[ $EUID -ne 0 ]]; then
    echo "You must be root to run this script"
    exit 1
fi

echo "settings.py and wsgi.py will not be synced"

rsync -avzrl --exclude-from $EXCLUDE_FILE --progress $NETDELTA_CODEBASE_ROOT/ $NETDELTA_DOCKER_VOL_ROOT/
