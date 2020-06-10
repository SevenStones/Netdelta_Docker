#!/usr/bin/env bash

BASE_DIR="/home/iantibble"
DOCKER_BASE="${BASE_DIR}/netdd"
NETDELTA_DOCKER_ROOT="${DOCKER_BASE}/vol_server/nd_base/netdelta"
NETDELTA_ROOT="${BASE_DIR}/jango/netdelta"
EXCLUDE_FILE="${BASE_DIR}/netdelta_sites/scripts/config/sync-excludes.txt"

echo "settings.py and wsgi.py will not be synced"

rsync -avzrl --exclude-from $EXCLUDE_FILE --progress $NETDELTA_ROOT/ $NETDELTA_DOCKER_ROOT/
