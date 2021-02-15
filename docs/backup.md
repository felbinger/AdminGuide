I suspended all file backup projects ([GBM](https://github.com/felbinger/GBM), [PyBackup](https://github.com/felbinger/PyBackup)). 
I suggest you use [borg backup](https://borgbackup.readthedocs.io/en/stable/) for file backups. You can use my [DBM](https://github.com/felbinger/dbm) to get the database backups from your docker container.

### Docker Backup Manager (DBM)
The [docker backup management](https://github.com/felbinger/dbm) is a docker image to back up the database and ldap server inside your docker container. 
It's basicly a bash script which uses the docker network to access the database servers.  

You can simply create a script which runs the container with the required environment variables to create the backup.  

!!! warning "Security Warning"
    Note that all scripts executed by a root cronjob, should only be editable by root. Otherwise a lower privileged user, might be able to gain higher privileges ([Privilege Escalation](https://en.wikipedia.org/wiki/Privilege_escalation)).  

You're script may look like this, you may remove the environmentment variables you don't need.  

```shell
#!/bin/bash

docker run --rm -it \
  -v '/var/backups/:/data/' \
  -e "LDAP_HOST=main_ldap_1" \
  -e "LDAP_BASE_DN=dc=domain,dc=de" \
  -e "LDAP_BIND_DN=cn=admin,dc=domain,dc=de" \
  -e "LDAP_BIND_PW=S3cr3T" \
  -e "MARIADB_HOST=main_mariadb_1" \
  -e "MARIADB_DATABASES=mysql mariadb_backup nonexistent" \
  -e "MARIADB_PASSWORD=S3cr3T" \
  -e "MARIADB_USERNAME=root" \
  -e "POSTGRES_HOST=main_postgres_1" \
  -e "POSTGRES_USERNAME=postgres" \
  -e "POSTGRES_PASSWORD=S3cr3T" \
  -e "POSTGRES_DATABASES=postgres_backup postgres nonexistent" \
  -e "MONGODB_HOST=main_mongo_1" \
  -e "MONGODB_PASSWORD=S3cr3T" \
  -e "MONGODB_DATABASES=admin nonexistent" \
  --network=database \
  ghcr.io/felbinger/dbm
```

I really suggest creating a separate database user which can only create backups.  
Checkout the documentation for your dbms:

!!! warning ""
    If you created these users for the old backup (eighter pybackup or gbm), you probally limited these users to the localhost. 
    The DBM creates the backup over the network, so it can't use a user which is limited to localhost. Make sure to adjust the privileges.

- [MariaDB](https://mariadb.com/kb/en/create-user/)
  ```bash
  # example for mariadb (you need SELECT and LOCK TABLES permissions)
  $ sudo docker-compose exec mariadb mysql -u root -pS3cr3T
  mariadb> CREATE USER 'backup'@'%' IDENTIFIED BY 'secret_password_for_backup_user';
  mariadb> GRANT SELECT, LOCK TABLES ON mysql.* TO 'backup'@'localhost';
  # add privileges to all databases that you want to backup!
  mariadb> FLUSH PRIVILEGES;
  mariadb> EXIT;
  ```
- [PostgreSQL](https://www.postgresql.org/docs/8.0/sql-createuser.html)
- [MongoDB](https://docs.mongodb.com/manual/reference/method/db.createUser/)

Backups should also be scheduled using cronjob:
```
# database backups using docker backup management every three hours
0 */3 * * * /bin/bash /root/db_backup.sh >/dev/null 2>&1
```

### Borg Backup
Like I mentioned above, I'm currently using borg for file backups. Checkout the [official documentation](https://borgbackup.readthedocs.io/en/stable/#easy-to-use)

Create a backup repository:
```shell
borg init -e repokey /home/borg
```

Don't forget to export the repokey and save it somewhere safe!
```shell
borg key export /home/borg /home/user/borg.repokey
```

I created a script to perform the backups:
```shell
#!/bin/bash

export BORG_PASSPHRASE="<your_borg_repository_passphrase>"

# date in format: YYYY-MM-DD_HH-MM round to 15 minutes blocks
DATE=$(date +"%Y-%m-%d_%H")-$(echo "$(date +%M) - ($(date +%M)%15)" | bc)

PATHS=(
  "/srv/"
  "/home/admin/"
  "/root/"
  "/etc/ssh/sshd_config"
  "/etc/telegraf/telegraf.conf"
)

borg create --stats --progress -C lzma,5 /home/borg::${DATE} ${PATHS[@]}
```

The script is being executed by a crontab every night:
```
# run borg backup at 4 am
0 4 * * * /bin/bash /root/backup.sh >/dev/null 2>&1
```

I also created a script to pack the whole borg repository into a tar file:
```shell
#!/bin/bash

export BORG_PASSPHRASE="<your_borg_repository_passphrase>"
latest=$(borg list /home/borg | tail -1 | cut -d " " -f 1)

# extract last full backup from repository
#borg export-tar --progress "/home/borg::${latest}" "/home/user/${latest}.tar"

# validate that bork is not in use
while [[ -n $(pidof -x $(which borg)) ]]; do
  sleep 60
done

# pack backup repository
tar -cvf /home/user/backup_repository.tar /home/borg

chown user:user /home/user/backup_repository.tar
chmod 664 /home/user/backup_repository.tar
```
