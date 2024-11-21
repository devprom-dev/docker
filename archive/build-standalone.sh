#!/bin/bash
cat << _EOF_ > Dockerfile
FROM debian:11.10
MAINTAINER Evgeny Savitsky <evgeny.savitsky@devprom.ru>

#
ENV CROSS_COMPILE=/usr/bin/
ENV MYSQL_ROOT_PASSWORD=
ENV MYSQL_PASSWORD=
ENV DEBIAN_FRONTEND noninteractive

#
VOLUME /var/www/devprom
VOLUME /var/lib/mysql

#
RUN apt-get -y update && apt-get -y install cron apache2 default-mysql-server default-mysql-client \
  php7.4 php7.4-mysql libapache2-mod-php7.4 php7.4-gd php7.4-common php7.4-bcmath \
  php7.4-mysqli php7.4-curl php7.4-imap php7.4-ldap php7.4-xml php7.4-mbstring php7.4-zip php7.4-imagick \
   zip unzip wget git tzdata apt-utils rsyslog default-jre libreoffice-common libreoffice-writer \
  libreoffice-java-common vim postfix sasl2-bin

RUN a2enmod rewrite deflate filter setenvif headers ldap ssl proxy proxy_http authnz_ldap authn_anon session session_cookie request auth_form session_crypto

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y vim postfix sasl2-bin && \
  postconf -e "mydestination = localhost" && \
  postconf -e "myhostname = devprom.local" && \
  postconf -e "smtpd_sasl_auth_enable=yes" && \
  postconf -e "broken_sasl_auth_clients=yes" && \
  postconf -e "smtpd_relay_restrictions=permit_sasl_authenticated,reject_unauth_destination" && \
  postconf -e "smtpd_sasl_security_options = noanonymous" && \
  echo noreply | saslpasswd2 -c -p -u devprom.local noreply && \
  ln  /etc/sasldb2 /var/spool/postfix/etc/sasldb2 && \
  adduser postfix sasl && \
  touch /var/log/mail.log

COPY smtp/smtpd.conf /etc/postfix/sasl/smtpd.conf

#
RUN echo "* * * * * www-data /usr/bin/php /var/www/devprom/htdocs/core/processjobs.php >/dev/null 2>&1" >>  /etc/crontab
RUN echo "" >>  /etc/crontab
RUN mkdir -p /var/www/devprom

#
RUN rm /etc/apache2/sites-available/* && rm /etc/apache2/sites-enabled/*
COPY php/devprom.ini /etc/php/7.4/apache2/conf.d/
COPY mysql/devprom.cnf /etc/mysql/conf.d/
COPY apache2/devprom.conf /etc/apache2/sites-available/
COPY apache2/ldap.conf /etc/apache2/sites-available/
RUN a2ensite devprom.conf

CMD ( set -e && \
  service cron start && \
  service rsyslog start && \
  service postfix start && \
  service mariadb start && \
  export APACHE_RUN_USER=www-data && export APACHE_RUN_GROUP=www-data && export APACHE_PID_FILE=/var/run/apache2/.pid && \
  export APACHE_RUN_DIR=/var/run/apache2 && export APACHE_LOCK_DIR=/var/lock/apache2 && export APACHE_LOG_DIR=/var/log/apache2 && \
  exec apache2 -DFOREGROUND )
_EOF_

docker pull debian:11.10
docker build -t devprom/alm:latest .
docker push devprom/alm:latest