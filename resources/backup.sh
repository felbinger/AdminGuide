#!/bin/bash

# load custom paths if the pathfile exists, otherwise create a new pathfile
pathfile="/root/.paths.sh"
if [ ! -f ${pathfile} ]; then
  echo 'export PATHS=("")' > ${pathfile}
fi
source ${pathfile}

PATHS=(
  "${PATHS[@]}"   # load paths from pathfile
  "/srv/"
  "/home/admin/"
  "/root/"
  "/etc/ssh/sshd_config"
  "/etc/network/"
)

[ -d /home/backups ] && PATHS=(
  "${PATHS[@]}"
  "/home/backups"
)

# load borg passphase
source /root/.borg.sh

# date in format: YYYY-MM-DD_HH-MM round to 15 minutes blocks
DATE=$(date +"%Y-%m-%d_%H")-$(echo "$(date +%M) - ($(date +%M)%15)" | bc)

borg create --stats --progress -C lzma,5 /home/borg::${DATE} ${PATHS[@]}

# remove database backups
[ -d /home/backups ] && rm -r /home/backups/
