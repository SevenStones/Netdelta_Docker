FROM ubuntu:18.04
#thanks to BirgerK <birger.kamp@gmail.com> for letsencrypt 
MAINTAINER ian.tibble@netdelta.io 

ARG SITE
ENV SITE ${SITE:-default}
ARG PORT
ENV PORT ${PORT:-8000}
ENV DEBIAN_FRONTEND noninteractive
ENV LETSENCRYPT_HOME /etc/letsencrypt

ENV WEBMASTER_MAIL "ian.tibble@netdelta.io"
ENV DOCKYARD_SRC=nd_base
ENV DOCKYARD_CONFIG=config_base
# Directory in container for all project files
ENV DOCKYARD_SRVHOME=/srv
# Directory in container for project source files
ENV DOCKYARD_SRVPROJ=/srv/netdelta
ENV DOCKYARD_STAGING=/srv/staging
ENV VENVDIR=/srv/netdelta304

ENV DOMAINS "${SITE}.netdelta.io"

# Manually set the apache environment variables in order to get apache to work immediately.
RUN mkdir -p /etc/container_environment
RUN echo $WEBMASTER_MAIL > /etc/container_environment/WEBMASTER_MAIL && \
    echo $DOMAINS > /etc/container_environment/DOMAINS && \
    echo $LETSENCRYPT_HOME > /etc/container_environment/LETSENCRYPT_HOME

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
RUN mkdir -pv /srv/netdelta
RUN mkdir -pv /srv/${SITE}/logs

COPY $DOCKYARD_SRC $DOCKYARD_STAGING
COPY $DOCKYARD_CONFIG $DOCKYARD_STAGING


RUN cd /srv && python3 -m venv netdelta304
RUN chmod 755 $VENVDIR/bin/activate

COPY $DOCKYARD_CONFIG/config/requirements.txt $VENVDIR

RUN $VENVDIR/bin/pip3 install wheel
RUN $VENVDIR/bin/pip3 install -r $VENVDIR/requirements.txt

#COPY ./run_netdelta.sh /srv/staging
VOLUME [ "$LETSENCRYPT_HOME", "/srv/netdelta", "/srv/logs"]
ENTRYPOINT ["/srv/staging/config/run_web.sh"]
