#!/bin/bash


service mysql start
service rabbitmq-server start

#mkdir /var/www

#echo
#echo
#echo "listing staging"
#echo "---------------"
#find /srv/staging -maxdepth 4 -exec ls -ld "{}" \;

# ------Setting up modified libnmap
#cp -v /srv/staging/modified-libnmap-process.py /usr/local/lib/python2.7/dist-packages/libnmap/process.py

cd /srv/netdelta

# --------Apache config
#mkdir -pv /etc/letsencrypt/live/crosskey.netdelta.io
#mkdir -pv /var/www/html
#echo "default" > /var/www/html/index.html
#echo "crosskey" > /var/www/html/a/index.html
#echo "everycity" > /var/www/html/b/index.html
service apache2 start
#cp -v /srv/staging/apache2/ports.conf /etc/apache2/ports.conf

## -------Setting netdelta Django project environment
#echo "starting project netdelta"
#su -m iantibble -c "django-admin startproject netdelta"
#
#echo "starting app nd"
#su -m iantibble -c "django-admin startapp nd"
##ls -l /srv/netdelta/nd
#
#
## ------Sync other netdelta files from staging to production
#rsync -azrl /srv/staging/ /srv/netdelta/
##rm -r /srv/staging
#mv -v /srv/netdelta/fixperms.bash /usr/local/bin/
#/usr/local/bin/fixperms.bash
#
#certbot -n --expand --apache --agree-tos --email $WEBMASTER_MAIL --domains $DOMAINS
#
## prepare init migration
#su -m iantibble -c "python manage.py makemigrations nd" 
## migrate db, so we have the latest db schema
#su -m iantibble -c "python manage.py migrate"  
## start development server on public ip interface, on port 8000
##su -m iantibble -c "python manage.py runserver 0.0.0.0:8000"
## start celery worker
su -m iantibble -c "python manage.py celery worker --loglevel=info -B"
