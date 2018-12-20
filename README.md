# Dropbox in Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/smokex365/docker-dropbox-ext4.svg?maxAge=2592000)][hub]
[![License](https://img.shields.io/github/license/janeczku/docker-alpine-kubernetes.svg?maxAge=2592000)]()

[hub]: https://hub.docker.com/r/smokex365/docker-dropbox-ext4/

Run Dropbox inside Docker. Fully working with local host folder mount or inter-container linking (via `--volumes-from`).

This repository is based on the [janeczku/dropbox](https://registry.hub.docker.com/u/janeczku/dropbox/) image and attempts to fix the file system error as a result of recent changes to the Dropbox client (no longer works on ext2 which the container uses).

## Usage examples

### Quickstart

    docker run -d --restart=always --name=dropbox janeczku/dropbox

### Dropbox data mounted to local folder on the host

    docker run -d --restart=always --name=dropbox \
    -v /path/to/localfolder:/dbox/Dropbox \
    smokex365/docker-dropbox-ext4

### Run dropbox with custom user/group id
This fixes file permission errrors that might occur when mounting the Dropbox file folder (`/dbox/Dropbox`) from the host or a Docker container volume. You need to set `DBOX_UID`/`DBOX_GID` to the user id and group id of whoever owns these files on the host or in the other container.

    docker run -d --restart=always --name=dropbox \
    -e DBOX_UID=110 \
    -e DBOX_GID=200 \
    smokex365/docker-dropbox-ext4

### Enable LAN Sync

    docker run -d --restart=always --name=dropbox \
    --net="host" \
    smokex365/docker-dropbox-ext4

## Linking to Dropbox account after first start

Check the logs of the container to get URL to authenticate with your Dropbox account.

    docker logs dropbox

Copy and paste the URL in a browser and login to your Dropbox account to associate.

    docker logs dropbox

You should see something like this:

> "This computer is now linked to Dropbox. Welcome xxxx"

## Manage exclusions and check sync status

    docker exec -t -i dropbox dropbox help

## ENV variables

**DBOX_UID**  
Default: `1000`  
Run Dropbox with a custom user id (matching the owner of the mounted files)

**DBOX_GID**  
Default: `1000`  
Run Dropbox with a custom group id (matching the group of the mounted files)

**$DBOX_SKIP_UPDATE**  
Default: `False`  
Set this to `True` to skip updating to the latest Dropbox version on container start


## Exposed volumes

`/dbox/Dropbox`
Dropbox files

`/dbox/.dropbox`
Dropbox account configuration
