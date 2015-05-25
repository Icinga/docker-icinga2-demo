# docker-icinga2

> **Note**
>
> This is unfinished work-in-progress and will be moved
> to an official icinga repository once finished.

This repository is used as source for the
docker image `icinga/icinga2`.

## Requirements

* Docker >= 1.6.0

## TODOs

* supervisord config
* default icingaweb2 config including symlinks
* demo config for icinga2
* snapshot or release packages?
* more than centos7
* install icinga2 syntax highlighting for vim
* systemd support (requires privileged run)
* documentation

## Image details

* Based on centos:centos7 (similar to the Vagrant boxes)
* Icinga 2 w/ DB IDO MySQL, Icinga Web 2, MariaDB, Apache2
* Default installation/credentials. Use at your own risk.

## Usage

Start a new privileged container, bind the cgroups and port 80:

    $ sudo docker run -ti -p 3080:80 icinga/icinga2:latest

    $ sudo docker run -ti -p 3080:80 icinga/icinga2 /bin/bash

Build a new container based on this repository:

    $ sudo docker build -t icinga/icinga2 .

### Icinga Web 2

Icinga Web 2 can be accessed at /icingaweb2 w/ icingaadmin:icinga as credentials.

## Volumes

    /etc/icinga2
    /etc/icingaweb2
    /var/lib/icinga2
