#!/bin/bash

echo "Adjusting mysql filesystem permissions"
groupmod -g 112 mysql
usermod -u 108 -g 112 mysql
chown -Rv mysql:mysql /var/log/mysql
chown -Rv mysql:mysql /var/lib/mysql
chown -Rv mysql:mysql /data
sed -i -E "s/127\.0\.0\.1/0\.0\.0\.0/g" /etc/mysql/mysql.conf.d/mysqld.cnf
echo "sleeping 20"
sleep 20
service mysql start

mysql --user="root" --password="ankSQL4r4" --execute="use mysql;update user set host='%' where user='root';FLUSH PRIVILEGES;"
tail -f /dev/null
