# Backup

I suspended all backup projects ([GBM](https://github.com/felbinger/GBM),
[PyBackup](https://github.com/felbinger/PyBackup), [DBM](https://github.com/felbinger/dbm)). 
My suggestion is, to use [borg backup](https://borgbackup.readthedocs.io/en/stable/).

## [Borg Backup](https://borgbackup.readthedocs.io/en/stable/#easy-to-use)

You can create a borg repository using:
```shell
borg init -e repokey /home/borg
```

Don't forget to export the repokey and save it somewhere safe:
```shell
borg key export /home/borg /home/user/borg.repokey
```

I created a script to perform the backups:
```shell
# /root/backup.sh
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
  "/etc/nginx/sites-available/"
  "/etc/ssh/sshd_config"
  "/etc/network/"
)

# load borg passphase
source /root/.borg.sh

# date in format: YYYY-MM-DD_HH-MM round to 15 minutes blocks
DATE=$(date +"%Y-%m-%d_%H")-$(echo "$(date +%M) - ($(date +%M)%15)" | bc)
```
```shell
# /root/.borg.sh
export BORG_PASSPHRASE="<your_borg_repository_passphrase>"
```

The script is being executed by a crontab every night:
```
# run borg backup at 4 am
0 4 * * * /bin/bash /root/backup.sh >/dev/null 2>&1
```

I also created a script to pack the whole borg repository into a tar file:

```shell
#!/bin/bash

EXPORT_DIR="/home/exporter"

source /root/.borg.sh

# make sure borg is not in use
while [[ -n $(pidof -x $(which borg)) ]]; do
  sleep 60
done

tar -cvf ${EXPORT_DIR}/.backup_repository.tar /home/borg
if [ $? != 0 ]; then
  exit 1
fi

md5sum ${EXPORT_DIR}/.backup_repository.tar > ${EXPORT_DIR}/.backup_repository.md5sum.txt
if [ $? != 0 ]; then
  exit 1
fi

mv ${EXPORT_DIR}/{.,}backup_repository.tar
mv ${EXPORT_DIR}/{.,}backup_repository.md5sum.txt
sed -i "s|${EXPORT_DIR}/.backup_repository.tar|${EXPORT_DIR}/backup_repository.tar|g" ${EXPORT_DIR}/backup_repository.md5sum.txt

chown exporter:exporter ${EXPORT_DIR}/backup_repository.{tar,md5sum.txt}
chmod 664 ${EXPORT_DIR}/backup_repository.{tar,md5sum.txt}
```
