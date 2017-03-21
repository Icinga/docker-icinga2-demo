#/******************************************************************************
# * docker-icinga2-demo                                                            *
# * Dockerfile for Icinga 2 and Icinga Web 2                                   *
# * Copyright (C) 2015-2017 Icinga Development Team (https://www.icinga.com)   *
# *                                                                            *
# * This program is free software; you can redistribute it and/or              *
# * modify it under the terms of the GNU General Public License                *
# * as published by the Free Software Foundation; either version 2             *
# * of the License, or (at your option) any later version.                     *
# *                                                                            *
# * This program is distributed in the hope that it will be useful,            *
# * but WITHOUT ANY WARRANTY; without even the implied warranty of             *
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
# * GNU General Public License for more details.                               *
# *                                                                            *
# * You should have received a copy of the GNU General Public License          *
# * along with this program; if not, write to the Free Software Foundation     *
# * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.             *
# ******************************************************************************/

FROM centos:centos7

MAINTAINER Icinga Development Team

# for systemd
ENV container docker

RUN yum -y update; yum clean all; \
 yum -y install epel-release; yum clean all; \
 yum -y install http://packages.icinga.com/epel/7/release/noarch/icinga-rpm-release-7-1.el7.centos.noarch.rpm; yum clean all

# docs are not installed by default https://github.com/docker/docker/issues/10650 https://registry.hub.docker.com/_/centos/
# official docs are wrong, go for http://superuser.com/questions/784451/centos-on-docker-how-to-install-doc-files
# we'll need that for mysql schema import for icingaweb2
RUN [ -f /etc/rpm/macros.imgcreate ] && sed -i '/excludedocs/d' /etc/rpm/macros.imgcreate || exit 0
RUN [ -f /etc/yum.conf ] && sed -i '/nodocs/d' /etc/yum.conf || exit 0

RUN yum -y install vim hostname bind-utils cronie logrotate supervisor openssh openssh-server openssh-client rsyslog sudo passwd sed which vim-enhanced pwgen psmisc mailx \
 httpd nagios-plugins-all mariadb-server mariadb-libs mariadb; \
 yum -y install --enablerepo=icinga-snapshot-builds icinga2 icinga2-doc icinga2-ido-mysql icingaweb2 icingacli php-ZendFramework php-ZendFramework-Db-Adapter-Pdo-Mysql; \
 yum clean all;

# create api certificates and users (will be overridden later)
RUN icinga2 api setup

# set icinga2 NodeName and create proper certificates required for the API
RUN sed -i -e 's/^.* NodeName = .*/const NodeName = "docker-icinga2-demo"/gi' /etc/icinga2/constants.conf; \
 icinga2 pki new-cert --cn docker-icinga2-demo --key /etc/icinga2/pki/docker-icinga2-demo.key --csr /etc/icinga2/pki/docker-icinga2-demo.csr; \
 icinga2 pki sign-csr --csr /etc/icinga2/pki/docker-icinga2-demo.csr --cert /etc/icinga2/pki/docker-icinga2-demo.crt;

# includes supervisor config
ADD content/ /
RUN chmod u+x /opt/icinga2/initdocker


# no PAM
# http://stackoverflow.com/questions/18173889/cannot-access-centos-sshd-on-docker
RUN sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config; \
 echo "sshd: ALL" >> /etc/hosts.allow; \
 rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key && \
 ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key && \
 ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
 echo 'root:icingar0xx' | chpasswd; \
 useradd -g wheel appuser; \
 echo 'appuser:appuser' | chpasswd; \
 sed -i -e 's/^\(%wheel\s\+.\+\)/#\1/gi' /etc/sudoers; \
 echo -e '\n%wheel ALL=(ALL) ALL' >> /etc/sudoers; \
 echo -e '\nDefaults:root   !requiretty' >> /etc/sudoers; \
 echo -e '\nDefaults:%wheel !requiretty' >> /etc/sudoers; \
 echo 'syntax on' >> /root/.vimrc; \
 echo 'alias vi="vim"' >> /root/.bash_profile; \
 echo 'syntax on' >> /home/appuser/.vimrc; \
 echo 'alias vi="vim"' >> /home/appuser/.bash_profile;

# fixes at build time (we can't do that at user's runtime)
# setuid problem https://github.com/docker/docker/issues/6828
# 4755 ping is required for icinga user calling check_ping
# can be circumvented for icinga2.cmd w/ mkfifo and chown
# (icinga2 does not re-create the file)
RUN mkdir -p /var/log/supervisor; \
 chmod 4755 /bin/ping /bin/ping6; \
 chown -R icinga:root /etc/icinga2; \
 mkdir -p /etc/icinga2/pki; \
 chown -R icinga:icinga /etc/icinga2/pki; \
 mkdir -p /var/run/icinga2; \
 mkdir -p /var/log/icinga2; \
 chown icinga:icingacmd /var/run/icinga2; \
 chown icinga:icingacmd /var/log/icinga2; \
 mkdir -p /var/run/icinga2/cmd; \
 mkfifo /var/run/icinga2/cmd/icinga2.cmd; \
 chown -R icinga:icingacmd /var/run/icinga2/cmd; \
 chmod 2750 /var/run/icinga2/cmd; \
 chown -R icinga:icinga /var/lib/icinga2; \
 usermod -a -G icingacmd apache >> /dev/null; \
 chown root:icingaweb2 /etc/icingaweb2; \
 chmod 2770 /etc/icingaweb2; \
 mkdir -p /etc/icingaweb2/enabledModules; \
 chown -R apache:icingaweb2 /etc/icingaweb2/*; \
 find /etc/icingaweb2 -type f -name "*.ini" -exec chmod 660 {} \; ; \
 find /etc/icingaweb2 -type d -exec chmod 2770 {} \;

# configure PHP timezone
RUN sed -i 's/;date.timezone =/date.timezone = UTC/g' /etc/php.ini

# ports (icinga2 api & cluster (5665), mysql (3306))
EXPOSE 22 80 443 5665 3306

# volumes
VOLUME ["/etc/icinga2", "/etc/icingaweb2", "/var/lib/icinga2", "/usr/share/icingaweb2", "/var/lib/mysql"]

# change this to entrypoint preventing bash login
CMD ["/opt/icinga2/initdocker"]
#ENTRYPOINT ["/opt/icinga2/initdocker"]

