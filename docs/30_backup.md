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

source /root/.borg.sh

# date in format: YYYY-MM-DD_HH-MM round to 15 minutes blocks
DATE=$(date +"%Y-%m-%d_%H")-$(echo "$(date +%M) - ($(date +%M)%15)" | bc)

PATHS=(
  "/srv/"
  "/home/admin/"
  "/root/"
  "/etc/nginx/sites-available/"
  "/etc/ssh/sshd_config"
  "/etc/network/interfaces"
)

borg create --stats --progress -C lzma,5 /home/borg::${DATE} ${PATHS[@]}
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

source /root/.borg.sh
latest=$(borg list /home/borg | tail -1 | cut -d " " -f 1)

# extract last full backup from repository
#borg export-tar --progress "/home/borg::${latest}" "/home/user/${latest}.tar"

# validate that bork is not in use
while [[ -n $(pidof -x $(which borg)) ]]; do
  sleep 60
done

# pack backup repository
tar -cvf /tmp/backup_repository.tar /home/borg

chown user:user /tmp/backup_repository.tar
chmod 664 /tmp/backup_repository.tar
```
