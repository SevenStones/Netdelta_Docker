FROM ubuntu:18.04
#thanks to BirgerK <birger.kamp@gmail.com> for letsencrypt 
MAINTAINER ian.tibble@netdelta.io 

ARG SITE
ENV SITE ${SITE:-default}
ARG PORT
ENV PORT ${PORT:-8000}
ENV DEBIAN_FRONTEND noninteractive

ENV DOCKYARD_SRC=vol_server/nd_base
ENV DOCKYARD_CONFIG=config_base
# Directory in container for all project files
ENV DOCKYARD_SRVHOME=/srv
# Directory in container for project source files
ENV DOCKYARD_SRVPROJ=/srv/netdelta
ENV DOCKYARD_STAGING=/srv/staging
ENV CONFIG_BASE=/srv/config_base
ENV VENVDIR=/srv/netdelta_venv

#CMD ["/sbin/my_init"]

# Base setup
# ADD resources/etc/apt/ /etc/apt/
RUN apt-get -y update && \
    apt-get install -q -y curl apache2 && \
    apt-get install -q -y apt-utils python3.6 python3-pip python3.6-dev mysql-client net-tools rsync python-mysqldb rabbitmq-server && \
    apt-get install -q -y nmap postfix phpmyadmin iputils-ping python3-venv apache2-dev netcat-openbsd vim openssh-server ntpdate

RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:certbot/certbot
RUN apt-get install -y python-certbot-apache

#RUN apt-get install -y debconf-utils && \
#    echo mysql-server mysql-server/root_password password ankSQL4r4 | debconf-set-selections && \
#    echo mysql-server mysql-server/root_password_again password ankSQL4r4 | debconf-set-selections && \
#    apt-get install -y mysql-server -o pkg::Options::="--force-confdef" -o pkg::Options::="--force-confold" --fix-missing && \
#    apt-get clean

RUN apt-get remove -y python3-dev

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/www/html/

# configure apache
ADD $DOCKYARD_CONFIG/config/ports.conf /etc/apache2/

RUN echo "ServerName localhost" >> /etc/apache2/conf-enabled/hostname.conf && \
    a2enmod ssl headers proxy proxy_http proxy_html xml2enc rewrite usertrack remoteip && \
    mkdir -p /var/lock/apache2 && \
    mkdir -p /var/run/apache2

# configure runit
#RUN mkdir -p /etc/service/apache
#ADD config/scripts/run_apache.sh /etc/service/apache/run
#ADD config/scripts/init_letsencrypt.sh /etc/my_init.d/
#ADD config/scripts/run_letsencrypt.sh /run_letsencrypt.sh
#RUN chmod +x /*.sh && chmod +x /etc/my_init.d/*.sh 

# Stuff
# Port to expose
EXPOSE 80 443 ${PORT}
#CMD service mysql start && tail -F /var/log/mysql/error.log
RUN mkdir -pv /srv/staging
RUN mkdir -pv /srv/logs/${SITE}
RUN mkdir -pv /data

COPY $DOCKYARD_CONFIG $CONFIG_BASE

COPY $DOCKYARD_CONFIG/config/run_web.sh /srv

#COPY ./run_netdelta.sh /srv/staging
#VOLUME ["/etc/letsencrypt","/srv/staging", "/srv/logs", "/data", "/srv/netdelta_venv"]
ENTRYPOINT ["/srv/run_web.sh"]
