#!/bin/bash
WEBROOT=/var/www
NETDELTA_APP=/srv/netdelta
VENV=/srv/netdelta_venv

if [ "$1" == "-v" ]; then
  chgrp -Rv web $WEBROOT | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chown -Rv www-data $WEBROOT | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chmod -Rv ug+rwx $WEBROOT | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chmod -Rv o-rwx $WEBROOT | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chown -Rv iantibble:web $NETDELTA_APP | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chmod -Rv ug+rwx $NETDELTA_APP | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chmod -Rv o-rwx $NETDELTA_APP | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chown -Rv iantibble:web $VENV | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chmod -Rv ug+rwx $VENV | grep -i "changed" | grep -v "symbolic link" | grep -v grep
  chmod -Rv o-rwx $VENV | grep -i "changed" | grep -v "symbolic link" | grep -v grep
else
  chgrp -R web $WEBROOT
  chown -R www-data $WEBROOT
  chmod -R ug+rwx $WEBROOT
  chmod -R o-rwx $WEBROOT
  chown -R iantibble:web $NETDELTA_APP
  chmod -R ug+rwx $NETDELTA_APP
  chmod -R o-rwx $NETDELTA_APP
  chown -R iantibble:web $VENV
  chmod -R ug+rwx $VENV
  chmod -R o-rwx $VENV
fi