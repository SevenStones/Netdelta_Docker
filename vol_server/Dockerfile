FROM ubuntu

ENV DEBIAN_FRONTEND noninteractive
ENV DOCKYARD_STAGING=/srv/staging
ENV DOCKYARD_SRC=nd_base

RUN apt-get -y update && \
    apt-get install -q -y curl apache2 vim net-tools rsync apt-utils

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#RUN mkdir /srv
COPY volumes_server.bash /srv
RUN mkdir /logs
#RUN mkdir /data
RUN mkdir /srv/staging
RUN mkdir /le
RUN mkdir /data
RUN mkdir /srv/netdelta_venv
RUN useradd -s /bin/bash -d /home/iantibble -u 1000 -m iantibble
RUN groupadd -g 112 mysql
RUN useradd -u 108 -g 112 mysql
RUN groupadd web
RUN groupmod -g 1001 web
RUN usermod -G web iantibble
RUN chown -Rv iantibble:web /logs
RUN chown -Rv iantibble:web /srv/staging
RUN chowm -Rv iantibble:web /srv/netdelta_venv
RUN chown -Rv mysql:mysql /data

COPY $DOCKYARD_SRC $DOCKYARD_STAGING
RUN ls -laR $DOCKYARD_STAGING
EXPOSE 9600 80 443 22

#COPY ./run_netdelta.sh /srv/staging
VOLUME ["/srv/staging", "/logs", "/le", "/data", "/srv/netdelta_venv"]
ENTRYPOINT ["/srv/volumes_server.bash"]
