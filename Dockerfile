FROM debian:jessie
MAINTAINER Jan Broer <janeczku@yahoo.de>
ENV DEBIAN_FRONTEND noninteractive

# Download & install required applications: curl.
RUN apt-get -qqy update
RUN apt-get -qqy install wget python

# Create service account and set permissions.
RUN groupadd dropbox
RUN useradd -d /dbox -c "Dropbox Daemon Account" -s /usr/sbin/nologin -g dropbox dropbox
RUN mkdir -p /dbox/.dropbox /dbox/.dropbox-dist /dbox/Dropbox /dbox/base

# Download & install Dropbox 3.2.9 and latest python client
RUN wget -nv -O /dbox/base/dropbox.tar.gz "https://github.com/radio-astro/docker-dropbox/blob/master/dropbox-lnx.x86_64-3.2.9.tar.gz?raw=true"
RUN wget -nv -O /dbox/dropbox.py "https://www.dropbox.com/download?dl=packages/dropbox.py"

# Perform image clean up.
RUN apt-get -qqy autoclean

# Set permissions
RUN chown -R dropbox:dropbox /dbox

# Install script for managing dropbox init.
COPY run /dbox/
COPY dropbox /usr/local/bin/
RUN chmod +x /dbox/run /usr/local/bin/dropbox /dbox/dropbox.py

VOLUME ["/dbox/.dropbox", "/dbox/.dropbox-dist", "/dbox/Dropbox"]

# Dropbox Lan-sync
EXPOSE 17500

CMD ["/dbox/run"]
