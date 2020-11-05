
Afterwards you can add your services to the `docker-compose.yml`

* Reverse Proxy
  * [jwilder/nginx-proxy](./services/nginx-proxy.md)
  * [Traefik](./services/traefik.md)

* Webserver
  * [nginx](./services/nginx.md)
  * [httpd with php](./services/httpd.md)

* Databases
* [MariaDB + phpMyAdmin](./services/mariadb.md)
* [MongoDB](./services/mongodb.md)
* [PostgreSQL + pgAdmin 4](./services/postgresql.md)
* [Redis](./services/redis.md)

I suggest you to stop administrative services over the night. They shouln't be online for longer then needed, you can do this using a cronjob:
```bash
# stop administrative services at 5 am during the week
00 05 * * 1-5 /usr/local/bin/docker-compose -f /home/admin/services/main/docker-compose.yml rm -fs phpmyadmin pgadmin 2>&1
```

### [ctop](https://ctop.sh/)
Simple commandline monitoring tool for docker containers:
```
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.3/ctop-0.7.3-linux-amd64 \
  -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
```

### Docker Network Viewer
A simple tool to show docker networks:
```
sudo wget https://github.com/felbinger/DNV/releases/download/v0.1/dnv \
  -O /home/admin/tools/dnv
sudo chmod +x /home/admin/tools/dnv
```

## Backup

**I'm currently working on a new backup tool written in golang**, this could be an alternative if you don't want to install the latest version of python on your server.

I wrote [my own backup script in python](https://github.com/felbinger/pybackup).

**Security Reminder**: Due to the fact that the backup.py will be executed by root cronjob, the file should be only editable by root. Otherwise a lower privileged user, might add `/etc/shadow` or something else to gain higher privileges ([Privilege Escalation](https://en.wikipedia.org/wiki/Privilege_escalation)).

<details>
  <summary>Show deprecated way to install python3.8 using the testing repository (this might break your system!)</summary>

```bash
# install python3.8 from debian/testing - WARNING: this might break your system (use with caution!)
echo -e '\n# python3.8\ndeb [arch=amd64] http://deb.debian.org/debian/ testing main' | sudo tee -a /etc/apt/sources.list
echo 'APT::Default-Release "stable";' | sudo tee /etc/apt/apt.conf.d/99defaultrelease
sudo apt update
sudo apt install -y -t testing python3.8 python3-pip
```

</details>

```bash
sudo apt-get install build-essential checkinstall libreadline-gplv2-dev \
  libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev \
  libc6-dev libbz2-dev libffi-dev zlib1g-dev
  
wget https://www.python.org/ftp/python/3.8.6/Python-3.8.6.tgz
tar xzf Python-3.8.6.tgz

cd Python-3.8.6
./configure --enable-optimizations --prefix=/opt/python/3.8
make -j$(nproc)
sudo make altinstall
 
echo "export PATH=/opt/python/3.8/bin:$PATH" >> /etc/profile.d/python3.8.sh
bash /etc/profile.d/python3.8.sh
```

```bash
# install git and clone repository
sudo apt install -y git
sudo git clone https://github.com/felbinger/pybackup /root/pybackup/
sudo pip3 install -r /root/pybackup/requirements.txt

# delete offside backup cause we don't need it on the server
rm -r /root/pybackup/OffsideBackup

# configure pybackup
nano /root/pybackup/.config.json

# run backup
$ python3.8 backup.py -df
```

I really suggest creating a separate database user which can only create backups. MySQL Example: 
```bash
$ sudo docker-compose exec mariadb mysql -u root -pSECRET_PASSWORD
mariadb> CREATE USER 'backup'@'localhost' IDENTIFIED BY 'SECRET_PASSWORD';
mariadb> GRANT SELECT, LOCK TABLES ON mysql.* TO 'backup'@'localhost';
# add privileges to all databases that you want to backup!
mariadb> FLUSH PRIVILEGES;
mariadb> EXIT;
```

### Scheduled Backups
Backups should also be scheduled using cronjob:
```
# file backups at 3 am every fifth day
00 03 */5 * * /usr/bin/python3.8 /root/pybackup/backup.py -c /root/pybackup/.config.json -f
# database backups at 2:50 am every day
50 02 * * * /usr/bin/python3.8 /root/pybackup/backup.py -c /root/pybackup/.config.json -d
```
