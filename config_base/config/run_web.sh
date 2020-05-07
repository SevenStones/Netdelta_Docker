#!/bin/bash

if [ $# -eq 0 ]; then
  echo "no parameter passed"
  exit 1
fi

DOMAIN="$1.netdelta.io"
WEBMASTER_MAIL="ian.tibble@netdelta.io"
GREEN='\033[0;32m'
NC='\033[0m' # No Color
VENV_ROOT="/srv/netdelta304"
MYSQL_DIR="${VENV_ROOT}/lib/python3.6/site-packages/django/db/backends/mysql"
LIBNMAP_DIR="${VENV_ROOT}/lib/python3.6/site-packages/libnmap"
SITE_ROOT="/srv"
CONFIG_ROOT="/srv/staging/config"

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


#mkdir -pv /srv/netdelta
chown -vR mysql:mysql /var/lib/mysql

useradd -s /bin/bash -d /home/iantibble -m iantibble
groupadd web
usermod -G web iantibble
usermod -G web www-data
#mkdir /var/www
chown -R www-data:web /var/www
chown -R iantibble:web /srv/netdelta
chown -R iantibble:web /srv/staging


echo "sleeping 10"
sleep 10
service mysql start
service rabbitmq-server start
mysql -e "CREATE DATABASE IF NOT EXISTS netdelta_$1 CHARACTER SET utf8 COLLATE utf8_unicode_ci;" --user=root --password=ankSQL4r4

echo "listing test"
ls -lR /srv/staging


echo "Setting up Django and Apache Logs"
mkdir -v ${SITE_ROOT}/netdelta/logs
touch ${SITE_ROOT}/netdelta/logs/netdelta.json
touch ${SITE_ROOT}/netdelta/logs/debug.json
touch ${SITE_ROOT}/netdelta/logs/crash.log
touch ${SITE_ROOT}/netdelta/logs/celery.log
chown -R iantibble:web ${SITE_ROOT}/netdelta/logs
chmod -R 775 ${SITE_ROOT}/netdelta/logs
mkdir -pv /var/www/html/$1


#certbot -n --expand --apache --agree-tos --email $WEBMASTER_MAIL --domains $DOMAINS
# -------Setting letsencrypt certs where we already have the certs issued
#if [ "$2" == "le" ]
#then
#	echo "will configure letsencrypt certs"
#	a2dissite crosskey-django.conf
#	a2ensite crosskey-django-le.conf
#fi

# -------Setting netdelta Django project environment
#cd /srv || { echo "directory /srv does not exist"; exit 1; }
#echo "starting project netdelta"
#su -m iantibble -c "$VENV_ROOT/bin/django-admin startproject netdelta"
##django-admin startproject netdelta
#
#echo "starting app nd"
#su -m iantibble -c "$VENV_ROOT/bin/django-admin startapp nd"
##django-admin startapp nd

echo "Syncing code base and tools"
rsync -azrlv --exclude-from=$CONFIG_ROOT/deploy-excludes.txt /srv/staging/ /srv/

echo "listing of /srv/netdelta304"
ls -lR /srv/netdelta304

#echo "Installing pip requirements"
#pip3 install wheel
#pip3 install -r /srv/staging/netdelta/requirements.txt


echo "Patching virtualenv"
patch_MySQL_base
patch_libnmap

echo "Adjusting settings.py database name"
cp -v $CONFIG_ROOT/settings.py ${SITE_ROOT}/netdelta/netdelta
sed -i -E "s/SITENAME/$1/g" ${SITE_ROOT}/netdelta/netdelta/settings.py

echo "netdelta database tables setup"
cd /srv/netdelta || { echo "directory /srv/netdelta does not exist"; exit 1; }
su -m iantibble -c "$VENV_ROOT/bin/python3 manage.py makemigrations nd"
# migrate db, so we have the latest db schema
su -m iantibble -c "$VENV_ROOT/bin/python3 manage.py migrate"

echo "from django.contrib.auth.models import User; User.objects.filter(email='itibble@gmail.com').delete();
User.objects.create_superuser('admin', 'itibble@gmail.com', 'octl1912')" | $VENV_ROOT/bin/python3 manage.py shell

echo "Adjusting wsgi.py"
cp -v $CONFIG_ROOT/wsgi.py ${SITE_ROOT}/netdelta/netdelta

echo "Removing mod_wsgi Apache module"
a2dismod mod_wsgi

echo "Adjusting apache2.conf"
cat $CONFIG_ROOT/apache2-conf-add-on.txt >> /etc/apache2/apache2.conf

echo -e "Adjusting Apache site files for $1.conf"
cp -v $CONFIG_ROOT/new.conf /etc/apache2/sites-available
mv -v /etc/apache2/sites-available/new.conf /etc/apache2/sites-available/$1.conf
sed -i -E "s/SITE/$1/g" /etc/apache2/sites-available/$1.conf


$CONFIG_ROOT/fixperms.bash
cp -v $CONFIG_ROOT/fixperms.bash /usr/local/bin

echo "enabling site"
a2ensite $1.conf

service apache2 restart

# start celery worker
su -m iantibble -c "${VENV_ROOT}/bin/celery worker -E -A nd -n $1 -Q $1 --loglevel=info -B --logfile=${SITE_ROOT}/netdelta/logs/celery.log"
tail -f /dev/null
