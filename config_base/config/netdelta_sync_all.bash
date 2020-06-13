#!/usr/bin/env bash
# This script syncs the code base under /srv/staging to container live code base under /srv/netdelta
# for all containers in the SITES file under /srv/config_base/config
# Ian Tibble - 10 June 2020
#
#  usage: docker exec -d netdelta_<site_name> sh -c '/srv/config_base/config/netdelta_sync.bash'
#
#
ROOT="/home/iantibble/netdd"
CONFIG_ROOT="${ROOT}/config_base/config"

[ -f "${CONFIG_ROOT}/SITES" ] || ( echo "No sites file found under $CONFIG_ROOT"; exit 1; )
[ -s "${CONFIG_ROOT}/SITES" ] || ( echo "Sites file empty under $CONFIG_ROOT"; exit 1; )

while read site; do
  docker exec -d netdelta_$site sh -c '$CONFIG_ROOT/netdelta_sync.bash'
done < ${CONFIG_ROOT}/SITES
