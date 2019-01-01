FROM debian:jessie
MAINTAINER Jan Broer <janeczku@yahoo.de>
ENV DEBIAN_FRONTEND noninteractive

# Following https://www.dropbox.com/install?os=lnx
RUN apt-get update; apt-get install -y curl python \
    && tmpdir=`mktemp -d` \
	&& curl -# -L https://www.dropbox.com/download?plat=lnx.x86_64 | tar xzf - -C $tmpdir \
	&& mkdir /opt/dropbox \
	&& mv $tmpdir/.dropbox-dist/* /opt/dropbox/ \
	&& rm -rf $tmpdir \
	&& curl -L https://www.dropbox.com/download?dl=packages/dropbox.py > /usr/bin/dropbox-cli \
	&& chmod +x /usr/bin/dropbox-cli \
	&& groupadd dropbox \
	&& useradd -m -d /dbox -c "Dropbox Daemon Account" -s /usr/sbin/nologin -g dropbox dropbox

# Install init script and dropbox command line wrapper
COPY run /root/
COPY dropbox /usr/bin/dropbox

WORKDIR /dbox/Dropbox
EXPOSE 17500
VOLUME ["/dbox/.dropbox", "/dbox/Dropbox"]
ENTRYPOINT ["/root/run"]
