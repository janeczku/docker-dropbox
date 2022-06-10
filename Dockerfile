FROM debian:buster
LABEL org.opencontainers.image.authors="Jan Broer <janeczku@yahoo.de>"
ENV DEBIAN_FRONTEND noninteractive

# Requirements for trusting their gpg key
RUN apt-get -qqy update && apt-get -qqy install gnupg2 curl && c_rehash
# Following 'How do I add or remove Dropbox from my Linux repository?' - https://www.dropbox.com/en/help/246
RUN echo 'deb https://linux.dropbox.com/debian buster main' > /etc/apt/sources.list.d/dropbox.list
# Dropbox uses the same key for deb and rpm packages, so it's faster to download the key directly
# from them rather than wait for the poor-old-slow mit keyserver
RUN curl -L https://linux.dropbox.com/fedora/rpm-public-key.asc | apt-key add -
RUN apt-get -qqy update
# Note 'ca-certificates' dependency is required for 'dropbox start -i' to succeed
RUN apt-get -qqy install ca-certificates dropbox libglapi-mesa libxext-dev \
	libxdamage-dev libxshmfence-dev libxxf86vm-dev libxcb-glx0 libxcb-dri2-0 libxcb-dri3-0 libxcb-present-dev
# Perform image clean up.
RUN apt-get -qqy autoclean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Create service account and set permissions.
RUN groupadd dropbox
RUN useradd -m -d /dbox -c "Dropbox Daemon Account" -s /usr/sbin/nologin -g dropbox dropbox

# Dropbox is weird: it insists on downloading its binaries itself via 'dropbox
# start -i'. So we switch to 'dropbox' user temporarily and let it do its thing.
USER dropbox
RUN mkdir -p /dbox/.dropbox /dbox/.dropbox-dist /dbox/Dropbox /dbox/base \
	&& echo y | dropbox start -i

# Switch back to root, since the run script needs root privs to chmod to the user's preferrred UID
USER root

# Dropbox has the nasty tendency to update itself without asking. In the processs it fills the
# file system over time with rather large files written to /dbox and /tmp. The auto-update routine
# also tries to restart the dockerd process (PID 1) which causes the container to be terminated.
RUN mkdir -p /opt/dropbox \
	# Prevent dropbox to overwrite its binary
	&& mv /dbox/.dropbox-dist/dropbox-lnx* /opt/dropbox/ \
	&& mv /dbox/.dropbox-dist/dropboxd /opt/dropbox/ \
	&& mv /dbox/.dropbox-dist/VERSION /opt/dropbox/ \
	&& rm -rf /dbox/.dropbox-dist \
	&& install -dm0 /dbox/.dropbox-dist \
	# Prevent dropbox to write update files
	&& chmod u-w /dbox \
	&& chmod o-w /tmp \
	&& chmod g-w /tmp \
	# Prepare for command line wrapper
	&& mv /usr/bin/dropbox /usr/bin/dropbox-cli

# Install init script and dropbox command line wrapper
COPY run /root/
COPY dropbox /usr/bin/dropbox

WORKDIR /dbox/Dropbox
EXPOSE 17500
VOLUME ["/dbox/.dropbox", "/dbox/Dropbox"]
ENTRYPOINT ["/root/run"]
