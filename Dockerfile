# Use a specific version of Debian as the base image
FROM debian:10.10

# Maintainer information
LABEL maintainer="Evgeny Savitsky <evgeny.savitsky@devprom.ru>"

# Environment variables
ENV CROSS_COMPILE=/usr/bin/ \
    DEBIAN_FRONTEND=noninteractive

# Install required packages and set up Apache, MySQL, PHP, and other dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    apache2 default-mysql-client \
    php php-mysql libapache2-mod-php php-gd php-common php-bcmath \
    php-mysqli php-curl php-imap php-ldap php-xml php-mbstring php-zip php-imagick \
    zip unzip wget git \
    tzdata apt-utils rsyslog default-jre vim postfix sasl2-bin \
    && a2enmod rewrite deflate filter setenvif headers ldap ssl proxy proxy_http authnz_ldap authn_anon session session_cookie request auth_form session_crypto \
    && echo "deb http://deb.debian.org/debian buster-backports main" > /etc/apt/sources.list.d/buster-backports.list \
    && apt-get update \
    && apt-get install --no-install-recommends -y -t buster-backports libreoffice-common libreoffice-writer libreoffice-java-common \
    && postconf -e "mydestination = localhost" \
    && postconf -e "myhostname = devprom.local" \
    && postconf -e "smtpd_sasl_auth_enable=yes" \
    && postconf -e "broken_sasl_auth_clients=yes" \
    && postconf -e "smtpd_relay_restrictions=permit_sasl_authenticated,reject_unauth_destination" \
    && postconf -e "smtpd_sasl_security_options = noanonymous" \
    && echo noreply | saslpasswd2 -c -p -u devprom.local noreply \
    && ln /etc/sasldb2 /var/spool/postfix/etc/sasldb2 \
    && adduser postfix sasl \
    && touch /var/log/mail.log \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY smtp/smtpd.conf /etc/postfix/sasl/smtpd.conf
COPY php/devprom.ini /etc/php/7.3/apache2/conf.d/
COPY apache2/devprom.conf /etc/apache2/sites-available/
COPY apache2/ldap.conf /etc/apache2/sites-available/

# Enable the devprom Apache site
RUN a2ensite devprom.conf

# Set up cron jobs and create necessary directories
RUN echo "* * * * * www-data /usr/bin/php /var/www/devprom/htdocs/core/processjobs.php >/dev/null 2>&1" >> /etc/crontab \
    && mkdir -p /var/www/devprom/backup /var/www/devprom/update /var/www/devprom/files /var/www/devprom/logs \
    && chown -R www-data:www-data /var/www/devprom && chmod -R 755 /var/www/devprom \
    && rm /etc/apache2/sites-available/* && rm /etc/apache2/sites-enabled/*

# Set volume for /var/www/devprom
VOLUME /var/www/devprom

# Start services and keep the container running
CMD set -e && \
    service cron start && \
    service rsyslog start && \
    service postfix start && \  
    chown www-data:www-data -R /var/www/devprom && \
    export APACHE_RUN_USER=www-data && \
    export APACHE_RUN_GROUP=www-data && \
    export APACHE_PID_FILE=/var/run/apache2/.pid && \
    export APACHE_RUN_DIR=/var/run/apache2 && \
    export APACHE_LOCK_DIR=/var/lock/apache2 && \
    export APACHE_LOG_DIR=/var/log/apache2 && \
    exec apache2 -DFOREGROUND