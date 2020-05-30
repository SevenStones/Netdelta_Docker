#!/bin/bash

useradd -s /bin/bash -d /home/iantibble -u 1000 -m iantibble
#groupadd -g 112 mysql
#useradd -u 108 -g 112 mysql
groupadd web
groupmod -g 1001 web
usermod -G web iantibble
chown -Rv iantibble:web /logs
chown -Rv iantibble:web /netdelta

tail -f /dev/null 
