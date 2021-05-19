#!/bin/bash

source /root/.borg.sh
source /root/.telegram.sh

# date in format: YYYY-MM-DD_HH-MM round to 15 minutes blocks
DATE=$(date +"%Y-%m-%d_%H")-$(echo "$(date +%M) - ($(date +%M)%15)" | bc)

PATHS=(
  "/srv/"
  "/home/admin/"
  "/home/backups/"
  "/root/"
  "/etc/ssh/sshd_config"
)

borg create --stats --progress -C lzma,5 /home/borg::${DATE} ${PATHS[@]}
code=$?
if [ ! -z ${TELEGRAM_TOKEN} ] && [ ${code} != 0 ]; then
  curl -X POST -H 'Content-Type: application/json' \
    -d '{"chat_id": "239086941", "text": "'$(hostname -f)': backup creation failed! ('${code}')", "disable_notification": true}' \
    https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage
fi
