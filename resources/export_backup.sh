#!/bin/bash

EXPORT_DIR="/home/exporter"

source /root/.borg.sh
source /root/.telegram.sh

# make sure bork is not in use
while [[ -n $(pidof -x $(which borg)) ]]; do
  sleep 60
  curl -X POST -H 'Content-Type: application/json' \
    -d '{"chat_id": "239086941", "text": "'$(hostname -f)': offside backup: waiting for borg to finish...", "disable_notification": true}' \
    https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage
done

tar -cvf ${EXPORT_DIR}/.backup_repository.tar /home/borg
if [ $? != 0 ]; then
  curl -X POST -H 'Content-Type: application/json' \
    -d '{"chat_id": "239086941", "text": "'$(hostname -f)': offside backup creation failed!", "disable_notification": true}' \
    https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage
fi

md5sum ${EXPORT_DIR}/.backup_repository.tar > ${EXPORT_DIR}/.backup_repository.md5sum.txt
if [ $? != 0 ]; then
  curl -X POST -H 'Content-Type: application/json' \
    -d '{"chat_id": "239086941", "text": "'$(hostname -f)': md5sum for offside backup creation failed!", "disable_notification": true}' \
    https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage
fi

mv ${EXPORT_DIR}/{.,}backup_repository.tar
mv ${EXPORT_DIR}/{.,}backup_repository.md5sum.txt
sed -i "s|${EXPORT_DIR}/.backup_repository.tar|${EXPORT_DIR}/backup_repository.tar|g" \
  ${EXPORT_DIR}/backup_repository.md5sum.txt

chown exporter:exporter ${EXPORT_DIR}/backup_repository.{tar,md5sum.txt}
chmod 664 ${EXPORT_DIR}/backup_repository.{tar,md5sum.txt}
