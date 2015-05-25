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

RUN yum -y update; yum clean all; \
 yum -y install epel-release; yum clean all; \
 yum -y install http://packages.icinga.org/epel/7/release/noarch/icinga-rpm-release-7-1.el7.centos.noarch.rpm; yum clean all

RUN yum -y install vim bind-utils cronie logrotate supervisor openssh-server rsyslog sudo pwgen psmisc \
 httpd nagios-plugins-all mariadb-server mariadb-libs mariadb; yum clean all; \
 yum -y install --enablerepo=icinga-snapshot-builds icinga2 icinga2-doc icinga2-ido-mysql icingaweb2 icingacli php-ZendFramework php-ZendFramework-Db-Adapter-Pdo-Mysql; \
 yum clean all;

# includes supervisor config
ADD content/ /
RUN chmod u+x /opt/icinga2/run

# no PAM
# http://stackoverflow.com/questions/18173889/cannot-access-centos-sshd-on-docker
RUN sed -i -e 's/^\(UsePAM\s\+.\+\)/#\1/gi' /etc/ssh/sshd_config; \
 echo -e '\nUsePAM no' >> /etc/ssh/sshd_config; \
 useradd -g wheel appuser; \
 echo 'appuser:appuser' | chpasswd; \
 sed -i -e 's/^\(%wheel\s\+.\+\)/#\1/gi' /etc/sudoers; \
 echo -e '\n%wheel ALL=(ALL) ALL' >> /etc/sudoers; \
 echo -e '\nDefaults:root   !requiretty' >> /etc/sudoers; \
 echo -e '\nDefaults:%wheel !requiretty' >> /etc/sudoers

# disable selinux
#RUN setenforce 0

# supervisor
RUN mkdir -p /var/log/supervisor

# ports
EXPOSE 22 80 443 5665

# volumes
VOLUME ["/etc/icinga2", "/etc/icingaweb2", "/var/lib/icinga2"]

# for root
RUN echo 'syntax on' >> /root/.vimrc; \
 echo 'alias vi="vim"' >> /root/.bash_profile; \
 echo 'syntax on' >> /home/appuser/.vimrc; \
 echo 'alias vi="vim"' >> /home/appuser/.bash_profile;

# change this to entrypoint preventing bash login
CMD ["/opt/icinga2/run"]
#ENTRYPOINT ["/opt/icinga2/run"]

