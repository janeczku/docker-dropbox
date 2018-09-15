FROM debian:jessie
MAINTAINER Daniel Rodgers-Pryor <djrodgerspryor@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

# Following 'How do I add or remove Dropbox from my Linux repository?' - https://www.dropbox.com/en/help/246
RUN echo 'deb http://linux.dropbox.com/debian jessie main' > /etc/apt/sources.list.d/dropbox.list \
    && apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E \
    && apt-get -qqy update \
    # Note 'ca-certificates' dependency is required for 'dropbox start -i' to succeed
    && apt-get -qqy install ca-certificates curl python-gpgme dropbox python3 \
    # Perform image clean up.
    && apt-get -qqy autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Create service account and set permissions.
    && groupadd dropbox \
    && useradd -m -d /dbox -c "Dropbox Daemon Account" -s /usr/sbin/nologin -g dropbox dropbox

# Dropbox is weird: it insists on downloading its binaries itself via 'dropbox
# start -i'. So we switch to 'dropbox' user temporarily and let it do its thing.
USER dropbox
RUN mkdir -p /dbox/.dropbox /dbox/.dropbox-dist /dbox/Dropbox /dbox/base \
    && echo y | dropbox start -i

# Switch back to root, since the run script needs root privs to chmod to the user's preferrred UID
USER root

# Install dropbox files-system support patch
ADD ./dropbox_ext4/* /tmp/dropbox_ext4/
WORKDIR /tmp/dropbox_ext4
RUN ./fix_dropbox.py \
    && cd .. \
    && rm -rf /tmp/dropbox_ext4
WORKDIR /

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

# Assert that dropbox points at the wrapper script set-up by the dropbox_ext4 patch, which set's the
# LD_PRELOAD path properly. The run script executes `dropbox` not `/usr/bin/dropbox`, so this means that the
# actual execution order will be:
#     /root/run -> /usr/local/bin/dropbox -> /usr/bin/dropbox -> /usr/bin/dropbox-cli
RUN [ "$(which dropbox)" = "/usr/local/bin/dropbox" ]

WORKDIR /dbox/Dropbox
EXPOSE 17500
VOLUME ["/dbox/.dropbox", "/dbox/Dropbox"]
ENTRYPOINT ["/root/run"]