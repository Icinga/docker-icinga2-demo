# docker-icinga2-demo

This repository is used as source for the
docker image `icinga/icinga2-demo` located at [Docker Hub](https://hub.docker.com/r/icinga/icinga2-demo/).

## Requirements

* [Docker](https://www.docker.com/whatisdocker/) >= 1.6.0

## Support

This container is used for demos, tests and development only.

If you encounter bugs, please open a new issue at https://github.com/icinga/docker-icinga2-demo
and/or send a PR.

## Image details

* Based on centos:centos7 (similar to the Vagrant boxes)
* Icinga 2 w/ DB IDO MySQL, Icinga Web 2, MariaDB, Apache2
* Icinga 2 API
* Default installation/credentials. Use at your own risk.

## Usage

### Run

Start a new container, bind the container's port 80 to localhost:3080
and let the initialization do its job:

    $ docker run -ti --name icinga2 -p 3080:80 icinga/icinga2

If you want to invoke it manually, go for

    $ docker run -ti --name icinga2 -p 3080:80 icinga/icinga2 /bin/bash
    # /opt/icinga2/initdocker

### Exec

Attach to a running container using `exec` and the container name.

    $ docker exec -ti icinga2 /bin/bash

### Stop

    $ docker stop icinga2

### Remove

    $ docker rm icinga2

### Container Build

Build a new container based on this repository:

    $ sudo docker pull centos:centos7
    $ sudo docker build -t icinga/icinga2 .

### SSH Access

Even if you can already mount specific [volumes](#volumes) there's ssh access
available. Make sure to map the port accordingly.

    $ sudo docker run -ti --name icinga2 -p 3080:80 -p 3022:22 icinga/icinga2

Then login as `appuser/appuser`. sudo is enabled for this user.

    $ ssh appuser@localhost -p 3022

## Tools

### Icinga 2

The configuration is located in /etc/icinga2 which is exposed as [volume](#volumes) from
docker.

By default the icinga database is created, and `ido-mysql` and `command` features
are enabled.

The container startup will validate the configuration once (e.g. if you have mounted
the volume).

#### Icinga 2 API

The container already enables the Icinga 2 API listening on port `5665`. Export the
port accordingly.

    docker run -d -ti --name icinga2-api -p 4080:80 -p 4665:5665 icinga/icinga2

After the container is up and running, connect via HTTP to the exposed port using
the credentials `root:icinga`.

Example for Docker on OSX (change the IP address to your localhost):

    curl -k -s -u root:icinga 'https://192.168.99.100:4665/v1/objects/hosts' | python -m json.tool


#### Icinga 2 Graphite Feature

In order to enable the Graphite feature at runtime (e.g. exposing port `2003` for a separate container
running Graphite) you'll need to pass the environment variables to the container.

  Environment Variable             | Description
  ---------------------------------|----------------------------------------------------
  ICINGA2\_FEATURE\_GRAPHITE       | Enables the Graphite feature
  ICINGA2\_FEATURE\_GRAPHITE\_HOST | **Required.** Host where Graphite is running on.
  ICINGA2\_FEATURE\_GRAPHITE\_PORT | **Required.** Port where Graphite is listening on.

Furthermore you'll need to `--link` the container to an existing container, e.g. `graphite` to allow
the link on port `2003` required by Graphite.

    docker run -d -ti --name icinga2 -p 3080:80 --link graphite:graphite -e ICINGA2_FEATURE_GRAPHITE=1 -e ICINGA2_FEATURE_GRAPHITE_HOST="192.168.99.100" -e ICINGA2_FEATURE_GRAPHITE_PORT=2003 icinga/icinga2

Example for a Graphite container called `graphite`:

    docker run -d --name graphite --restart=always -p 9090:80 -p 2003:2003 hopsoft/graphite-statsd

### Icinga Web 2

Icinga Web 2 can be accessed at http://localhost:3080/icingaweb2 w/ `icingaadmin:icinga` as credentials.

The configuration is located in /etc/icingaweb2 which is exposed as [volume](#volumes) from
docker.

By default the icingaweb2 database is created including the `icingaadmin` user. Additional
configuration is also added to skip the setup wizard.

## Ports

The following ports are exposed:

  Port     | Service
  ---------|---------
  22       | SSH
  80       | HTTP
  443      | HTTPS
  3306     | MySQL
  5665     | Icinga 2 API & Cluster

## Volumes

These volumes can be mounted in order to test and develop various stuff.

    /etc/icinga2
    /etc/icingaweb2

    /var/lib/icinga2
    /usr/share/icingaweb2

    /var/lib/mysql

# Thanks

* Jordan Jethwa for the initial [icinga2 docker image for Debian](https://github.com/jjethwa/icinga2)

