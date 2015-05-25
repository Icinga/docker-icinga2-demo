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

Start a new container, bind the container's port 80 to localhost:3080
and let the initialization do its job:

    $ sudo docker run -ti -p 3080:80 icinga/icinga2

If you want to invoke it manually, go for

    $ sudo docker run -ti -p 3080:80 icinga/icinga2 /bin/bash
    # /opt/icinga2/initdocker

Build a new container based on this repository:

    $ sudo docker pull centos:centos7
    $ sudo docker build -t icinga/icinga2 .


## Tools

### Icinga 2

The configuration is located in /etc/icinga2 which is exposed as volume from
docker.

By default the icinga database is created, and `ido-mysql` and `command` features
are enabled.

### Icinga Web 2

Icinga Web 2 can be accessed at http://localhost:3080/icingaweb2 w/ icingaadmin:icinga as credentials.

The configuration is located in /etc/icingaweb2 which is exposed as volume from
docker.

By default the icingaweb2 database is created including the `icingaadmin` user. Additional
configuration is also entered to skip the setup wizard.

## Ports

The following ports are exposed: 22, 80, 443, 3306, 5665

## Volumes

These volumes can be mounted in order to test various stuff.

    /etc/icinga2
    /etc/icingaweb2
    /var/lib/icinga2

# Thanks

* Jordan Jethwa for the initial [icinga2 docker image for Debian](https://github.com/jjethwa/icinga2)

