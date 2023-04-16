#!/bin/bash

# require root privileges
if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

# admin directory
chown -R root:admin /home/admin
find /home/admin -type d -exec chmod 0775 {} \;
find /home/admin -type f -exec chmod 0664 {} \;

# passphrases and tokens
chown root:root /root/.borg.sh
chmod 600 /root/.borg.sh

# exporter directory (sftp)
if [ -d /home/exporter ]; then
  chown -R root:root /home/exporter
  find /home/exporter -type d -exec chmod 0755 {} \;
fi

# service specific permissions
[ -d /srv/matrix/ ] && find /srv/matrix/ -type d -name mautrix-* -exec chown -R 991:1000 {} \;
[ -d /srv/matrix/synapse ] && chown -R 991:1000 /srv/matrix/synapse
[ -d /srv/grafana/ ] && chown -R 472:472 /srv/grafana
[ -d /srv/hackmd/ ] && chown -R 1500:1500 /srv/hackmd
[ -d /srv/bookstack/ ] && chown -R 911:911 /srv/bookstack
[ -d /srv/pgadmin/ ] && chown -R 5050:5050 /srv/pgadmin && find /srv/pgadmin/storage -type f -exec chmod 0600 {} \;
