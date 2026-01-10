aws --endpoint-url=https://storage.yandexcloud.net/ s3 cp s3://devprom-builds/latest/devprom-latest.zip /tmp/devprom.zip --no-sign-reques
mkdir -p /tmp/devprom/
unzip -o /tmp/devprom.zip -d /tmp/devprom/
cp -pr /tmp/devprom/devprom /opt
mkdir /opt/logs
mkdir /opt/update
mkdir /opt/backup
mv /opt/devprom /opt/htdocs
chown -R 33:33 /opt/