#!/bin/bash
cat << _EOF_ > Dockerfile
FROM debian:10.10
MAINTAINER Evgeny Savitsky <evgeny.savitsky@devprom.ru>

#
ENV CROSS_COMPILE=/usr/bin/

#
RUN apt-get -y update && apt-get -y install apache2 default-mysql-client \
  php php-mysql libapache2-mod-php php-gd php-common php-bcmath \
  php-mysqli php-curl php-imap php-ldap php-xml php-mbstring php-zip php-imagick \
  zip unzip wget git

RUN a2enmod rewrite deflate filter setenvif headers ldap ssl proxy authnz_ldap authn_anon session session_cookie request auth_form session_crypto

#
RUN apt-get -y update && apt-get -y install tzdata apt-utils rsyslog default-jre

RUN echo "deb http://deb.debian.org/debian buster-backports main" | tee /etc/apt/sources.list.d/buster-backports.list
RUN apt-get -y update
RUN apt-get -y install -t buster-backports libreoffice-common libreoffice-writer libreoffice-java-common

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
VOLUME /var/www/devprom

#
RUN mkdir /var/www/devprom/backup  && mkdir /var/www/devprom/update && \
  mkdir /var/www/devprom/files && mkdir /var/www/devprom/logs
RUN chown -R www-data:www-data /var/www/devprom && chmod -R 755 /var/www/devprom

#
RUN rm /etc/apache2/sites-available/* && rm /etc/apache2/sites-enabled/*
COPY php/devprom.ini /etc/php/7.3/apache2/conf.d/
COPY apache2/devprom.conf /etc/apache2/sites-available/
COPY apache2/ldap.conf /etc/apache2/sites-available/
RUN a2ensite devprom.conf && a2enmod proxy_http

CMD ( set -e && \
  service cron start && \
  service rsyslog start && \
  service postfix start && \
  chown www-data:www-data -R /var/www/devprom && \
  export APACHE_RUN_USER=www-data && export APACHE_RUN_GROUP=www-data && export APACHE_PID_FILE=/var/run/apache2/.pid && \
  export APACHE_RUN_DIR=/var/run/apache2 && export APACHE_LOCK_DIR=/var/lock/apache2 && export APACHE_LOG_DIR=/var/log/apache2 && \
  exec apache2 -DFOREGROUND )
_EOF_

docker pull debian:10.10
docker build -t devprom/alm-app:latest .
docker push devprom/alm-app:latest
