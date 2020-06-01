#!/bin/bash

chown -Rv mysql:mysql /var/log/mysql
chown -Rv mysql:mysql /var/lib/mysql
echo "sleeping 20"
sleep 20
service mysql start

tail -f /dev/null
