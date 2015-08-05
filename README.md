# Dropbox in Docker

Run Dropbox inside Docker. Fully working with local host folder mount or inter-container linking (via `--volumes-from`).

This repository provides the [janeczku/dropbox](https://registry.hub.docker.com/u/janeczku/dropbox/) image.

## Usage examples

### Quickstart

    docker run -d --restart=always --name=dropbox janeczku/dropbox

### Dropbox data mounted to local folder on the host

    docker run -d --restart=always --name=dropbox \
    -v /path/to/localfolder:/dbox/Dropbox \
    janeczku/dropbox

### Custom owner for the Dropbox files
This fixes file permission errrors that might occur when mounting the Dropbox volume to the host or another container. Just set UID/GID to the user/group that is going to access the Dropbox files.

    docker run -d --restart=always --name=dropbox \
    -e DBOX_UID=110 \
    -e DBOX_GID=200 \
    janeczku/dropbox

### Enable LAN Sync

    docker run -d --restart=always --name=dropbox \
    --net="host" \
    janeczku/dropbox

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
Set the owner of the Dropbox folder to a custom UID

**DBOX_GID**  
Default: `1000`  
Set the owner of the Dropbox folder to a custom GID

## Exposed volumes

`/dbox/.dropbox` 
Dropbox config folder

`/dbox/Dropbox`
Dropbox files
