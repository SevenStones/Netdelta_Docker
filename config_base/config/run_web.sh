#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Missing parameters; $1 - site name ]"
  exit 1
fi

if [ "$2" -lt 1024 ]; then
  echo "port must be > 1024"
  exit 1
fi

[[ "$#" -eq 3 ]] && [ "$3" != "le" ] && { echo "Invalid options: usage - run_web.sh site port [le]"; exit 1; }

DOMAIN="$1.netdelta.io"
WEBMASTER_MAIL="ian.tibble@netdelta.io"
GREEN='\033[0;32m'
NC='\033[0m' # No Color
VENV_ROOT="/srv/netdelta304"
MYSQL_DIR="${VENV_ROOT}/lib/python3.6/site-packages/django/db/backends/mysql"
LIBNMAP_DIR="${VENV_ROOT}/lib/python3.6/site-packages/libnmap"
SITE_ROOT="/srv"
CONFIG_ROOT="/srv/staging/config"
LOG_ROOT=${SITE_ROOT}/logs/$1
function patch_MySQL_base(){
  echo "Applying patch for base.py (MySQL Django framework)"
  cp -v ${MYSQL_DIR}/base.py ${MYSQL_DIR}/base.orig
  patch ${MYSQL_DIR}/base.py -i $CONFIG_ROOT/patches/base.patch \
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
  echo "Applying patch for libnmap"
  cp -v ${LIBNMAP_DIR}/process.py ${LIBNMAP_DIR}/process.orig
  patch ${LIBNMAP_DIR}/process.py -i $CONFIG_ROOT/patches/libnmap-process.patch \
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


#echo "Adjusting mysql filesystem permissions"
#chown -R mysql:mysql /var/lib/mysql

echo "Non-root users and groups config"
useradd -s /bin/bash -d /home/iantibble -u 1000 -m iantibble
groupadd web
groupmod -g 1001 web
usermod -G web iantibble
usermod -G web www-data
chown -R www-data:web /var/www
chown -R iantibble:web /srv/netdelta
chown -R iantibble:web /srv/staging

echo "sleeping 10"
sleep 10
#service mysql start
service rabbitmq-server start
echo "setting up database: netdelta_$1"
mysql -e "CREATE DATABASE IF NOT EXISTS netdelta_$1 CHARACTER SET utf8 COLLATE utf8_unicode_ci;" --user=root --password=ankSQL4r4 -h 127.0.0.1 -p 3306

echo "Setting up Django and Apache Logs"
mkdir -v ${LOG_ROOT}
touch ${LOG_ROOT}/netdelta.json
touch ${LOG_ROOT}/debug.json
touch ${LOG_ROOT}/request.json
touch ${LOG_ROOT}/crash.log
touch ${LOG_ROOT}/celery.log
touch ${LOG_ROOT}/celery-monitor.log
chown -R iantibble:web ${LOG_ROOT}
chmod -R 775 ${LOG_ROOT}
mkdir -pv /var/www/html/$1

echo "Syncing code base and tools"
rsync -azrlv --exclude-from=$CONFIG_ROOT/deploy-excludes.txt /srv/staging/ /srv/

echo "Patching virtualenv"
patch_MySQL_base
patch_libnmap

echo "Adjusting settings.py database name"
cp -v $CONFIG_ROOT/settings.py ${SITE_ROOT}/netdelta/netdelta
sed -i -E "s/SITENAME/$1/g" ${SITE_ROOT}/netdelta/netdelta/settings.py

echo "Adjusting filesystem permissions"
$CONFIG_ROOT/fixperms.bash
cp -v $CONFIG_ROOT/fixperms.bash /usr/local/bin

echo "Adjusting listening ports for Apache"
cp -v $CONFIG_ROOT/ports.conf /etc/apache2/ports.conf
sed -i -E "s/PORT/$2/g" /etc/apache2/ports.conf

echo "Enabling celery monitor init service"
cp -v $CONFIG_ROOT/celery-monitor.bash /etc/init.d
mv -v /etc/init.d/celery-monitor.bash /etc/init.d/celery-monitor
chmod -v 700 /etc/init.d/celery-monitor
update-rc.d celery-monitor defaults

echo "netdelta database tables setup"
cd /srv/netdelta || { echo "directory /srv/netdelta does not exist"; exit 1; }
su -m iantibble -c "$VENV_ROOT/bin/python3 manage.py makemigrations nd"
# migrate db, so we have the latest db schema
su -m iantibble -c "$VENV_ROOT/bin/python3 manage.py migrate"

echo "Setting Django admin password"
echo "from django.contrib.auth.models import User; User.objects.filter(email='itibble@gmail.com').delete();User.objects.create_superuser('admin', 'itibble@gmail.com', 'octl1912')" | $VENV_ROOT/bin/python3 manage.py shell

echo "Adjusting wsgi.py"
cp -v $CONFIG_ROOT/wsgi.py ${SITE_ROOT}/netdelta/netdelta

echo "Removing mod_wsgi Apache module - just to make sure, will flag an error probably"
a2dismod mod_wsgi

echo "Adjusting apache2.conf"
cat $CONFIG_ROOT/apache2-conf-add-on.txt >> /etc/apache2/apache2.conf

echo -e "Adjusting Apache site files for $1.conf"
cp -v $CONFIG_ROOT/new.conf /etc/apache2/sites-available
mv -v /etc/apache2/sites-available/new.conf /etc/apache2/sites-available/$1.conf
sed -i -E "s/SITE/$1/g" /etc/apache2/sites-available/$1.conf
sed -i -E "s/PORT/$2/g" /etc/apache2/sites-available/$1.conf

if [ "$3" == "le" ]; then
  echo "Letsencrypt operations"
  mkdir -v /etc/letsencrypt
  cp -v $CONFIG_ROOT/options-ssl-apache.conf /etc/letsencrypt
  sed -i -E "s/<\/VirtualHost>/g" /etc/apache2/sites-available/$1.conf
  cat $CONFIG_ROOT/letsencrypt-apache2.conf >> /etc/apache2/sites-available/$1.conf
  sed -i -E "s/SITE/$1/g" /etc/apache2/sites-available/$1.conf
  mkdir -pv /etc/letsencrypt/live/$1.netdelta.io
  cp -v $CONFIG_ROOT/certs/privkey.pem /etc/letsencrypt/live/$1.netdelta.io
  cp -v $CONFIG_ROOT/certs/fullchain.pem /etc/letsencrypt/live/$1.netdelta.io
  chmod -v 600 /etc/letsencrypt/live/$1.netdelta.io/privkey.pem
fi

echo "enabling site"
a2ensite $1.conf

service apache2 restart
service apache2 stop

echo "Adjusting filesystem permissions"
$CONFIG_ROOT/fixperms.bash

# start celery worker
su -m iantibble -c "${VENV_ROOT}/bin/celery worker -E -A nd -n $1 -Q $1 --loglevel=info -B --logfile=${LOG_ROOT}/celery.log"
tail -f /dev/null
