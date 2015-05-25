# Dockerfile for icinga2 as core and icingaweb2 as ui
# Using latest snapshot packages

FROM centos:centos7

MAINTAINER Michael Friedrich
# for systemd
ENV container docker

# docs are not installed by default https://github.com/docker/docker/issues/10650 https://registry.hub.docker.com/_/centos/
# official docs are wrong, go for http://superuser.com/questions/784451/centos-on-docker-how-to-install-doc-files
# we'll need that for mysql schema import for icingaweb2
RUN sed -i '/excludedocs/d' /etc/rpm/macros.imgcreate
RUN sed -i '/nodocs/d' /etc/yum.conf

RUN yum -y update; yum clean all
RUN yum -y install epel-release; yum clean all
RUN yum -y install http://packages.icinga.org/epel/7/release/noarch/icinga-rpm-release-7-1.el7.centos.noarch.rpm; yum clean all

RUN yum -y install vim bind-utils cronie logrotate supervisor openssh-server rsyslog sudo pwgen psmisc; yum clean all;

# includes supervisor config
ADD content/ /
RUN chmod u+x /opt/icinga2/run

# no PAM
# http://stackoverflow.com/questions/18173889/cannot-access-centos-sshd-on-docker
RUN sed -i -e 's/^\(UsePAM\s\+.\+\)/#\1/gi' /etc/ssh/sshd_config
RUN echo -e '\nUsePAM no' >> /etc/ssh/sshd_config

RUN useradd -g wheel appuser
RUN echo 'appuser:appuser' | chpasswd
RUN sed -i -e 's/^\(%wheel\s\+.\+\)/#\1/gi' /etc/sudoers
RUN echo -e '\n%wheel ALL=(ALL) ALL' >> /etc/sudoers

# allow sudo without tty for ROOT user and WHEEL group
# # http://qiita.com/ryo0301/items/4daf5a6d22f16193410f
RUN echo -e '\nDefaults:root   !requiretty' >> /etc/sudoers
RUN echo -e '\nDefaults:%wheel !requiretty' >> /etc/sudoers

RUN yum -y install httpd nagios-plugins-all mariadb-server mariadb-libs mariadb

RUN yum -y install --enablerepo=icinga-snapshot-builds icinga2 icinga2-doc icinga2-ido-mysql icingaweb2 icingacli

RUN yum -y install mariadb-server mariadb-libs mariadb

# disable selinux
#RUN setenforce 0

# fixes
RUN sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers

# supervisor
RUN mkdir -p /var/log/supervisor

# ports
EXPOSE 22 80 443 5665

# volumes
VOLUME ["/etc/icinga2", "/etc/icingaweb2", "/var/lib/icinga2"]

# for root
RUN echo 'syntax on'      >> /root/.vimrc
RUN echo 'alias vi="vim"' >> /root/.bash_profile
# for appuser
RUN echo 'syntax on'      >> /home/appuser/.vimrc
RUN echo 'alias vi="vim"' >> /home/appuser/.bash_profile

# additional hooks
CMD ["/opt/icinga2/run"]

