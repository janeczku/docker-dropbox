FROM debian:jessie
MAINTAINER Jan Broer <janeczku@yahoo.de>
ENV DEBIAN_FRONTEND noninteractive

# Following 'How do I add or remove Dropbox from my Linux repository?' - https://www.dropbox.com/en/help/246
RUN echo 'deb http://linux.dropbox.com/debian jessie main' > /etc/apt/sources.list.d/dropbox.list
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
RUN apt-get -qqy update
# Note 'ca-certificates' dependency is required for 'dropbox start -i' to succeed
RUN apt-get -qqy install ca-certificates dropbox
# Perform image clean up.
RUN apt-get -qqy autoclean

# Create service account and set permissions.
RUN groupadd dropbox
RUN useradd -m -d /dbox -c "Dropbox Daemon Account" -s /usr/sbin/nologin -g dropbox dropbox

# Dropbox is weird: it insists on downloading its biniaries itself via 'dropbox
# start -i'. So we switch to 'dropbox' user temporarily and let it do its thing.
USER dropbox
RUN mkdir -p /dbox/.dropbox /dbox/.dropbox-dist /dbox/Dropbox /dbox/base
RUN echo y | dropbox start -i

# Switch back to root, since the run script needs root privs to chmod to the user's preferrred UID
USER root
### Install script for managing dropbox init.
COPY run /root
RUN chmod +x /root/run 

# Dropbox Lan-sync
EXPOSE 17500

# Expose the .dropbox/ runtime status and Dropbox/ content files. This comes After 'dropbox start -i' in case the builder was 'docker-compose build', which mounts these and so can cause permission errors.
VOLUME ["/dbox/.dropbox", "/dbox/Dropbox"]

CMD ["/root/run"]
