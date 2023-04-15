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
