This Admin Guide describes how I setup my servers using docker.

### Installation

I created a script which can be executed to setup the server.  
I suggest you to get used to my structure (e.g. the stack logic), otherwise you might run into problems later on.  
If you never used this guide, you should [perform the installation manually](./installation/) to understand the structure.

<details>
  <summary>Post Installation Script</summary>

<br>
You can basicly skip most of the installation section, but there are some exceptions.

<ul>
  <li>
  First you should create all user accounts, and ensure that everyone is able to authenticate using public key authentication.
  </li>
  <li>
  You can add the users in the configuration section of the `postinstall.sh` to give them the groups, aliases, ... After you are sure that you can connect to the server you should secure your ssh server (e.g. disallow authentication using passwords, root login, ...).  
  </li>

  <li>
  If you want to change your hostname to something cooler than the name your hoster assigned you (this is not required, I do it to improve the identification process of the server, that I'm connected to).  
  </li>

  <li>
  You also need to setup your dns records, consider to change the name servers to cloudflare if you have trouble with the dns challenge for wildcard certificate later on.
  </li>
</ul>

```
curl -fsSL https://raw.githubusercontent.com/felbinger/AdminGuide/master/postinstall.sh | sudo bash
```

</details>

### Create your Services

After you successfully installed your system, you can add the services you need.  
Before you add a new service think which stack what fit best. It might be useful to create a new stack.

The following list contains a list of services that might come in handy. Simply add them to your `docker-compose.yml` and modify the required attributes (e.g. passwords, domain name, routing configuration, ...).

You can find all services (e.g. Gameserver, Teamspeak, Sinusbot, ...) in the navigation bar on the left side of your page.

#### Reverse Proxy's

A reverse proxy is a router which binds to the ports `80` (http) and `443` (https).  
You can access the configured services by connecting to the proxy (`https://domain.tld`) with a specific host header, which is going to be evaluated by the proxy.  
But how do you connect to your proxy with this specific host header? Due to the fact that you configured your dns to redirect all subdomains to your server you can simply access `https://phpmyadmin.domain.tld`. You will reach the reverse proxy on port 443 with the host header `phpmyadmin.domain.tld`, after evaluation the proxy will redirect the incomming request to the configured service.

- [Traefik](./services/traefik.md)
- [jwilder/nginx-proxy](./services/nginx-proxy.md) is no longer being maintained.

#### Webserver

There are a bunch of webservers out there, I use nginx or httpd (apache2) most of the time.

- [nginx](./services/nginx.md)
- [httpd](./services/httpd.md)
- [httpd with php](./services/httpd-php.md)

#### Databases

I like to put the admin webtool for database management right next to the database:

- [MariaDB + phpMyAdmin](./services/mariadb.md)
- [PostgreSQL + pgAdmin 4](./services/postgresql.md)
- [MongoDB](./services/mongodb.md)
- [Redis](./services/redis.md)

I recommend that you switch off the administrative services when not in use (e.g. overnight). Due to the fact that it is easy to forget this, you can also do this with a cronjob:

```bash
# stop administrative services at 5 am during the week
00 05 * * 1-5 /usr/local/bin/docker-compose -f /home/admin/services/main/docker-compose.yml rm -fs phpmyadmin pgadmin 2>&1
```

## Tools

### [ctop](https://ctop.sh/)

Simple commandline monitoring tool for docker containers:

```bash
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.3/ctop-0.7.3-linux-amd64 \
  -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
```

### Docker Network Viewer

A simple tool to show docker networks:

```bash
sudo wget https://github.com/felbinger/DNV/releases/download/v0.1/dnv \
  -O /usr/local/bin/dnv
sudo chmod +x /usr/local/bin/dnv
```

```sh
$ sudo ./dnv
bridge			172.17.0.0/16
proxy		  	192.168.0.0/24
database		192.168.1.0/24
monitoring	192.168.2.0/24
main			  192.168.100.0/24
storage			192.168.101.0/24
jitsi			  192.168.102.0/24
games			  192.168.103.0/24
```

### Backup

**I'm currently working on a new backup tool written in golang**, this could be an alternative if you don't want to install the latest version of python on your server.

Currently I use [my python backup script](https://github.com/felbinger/pybackup).

First you need to install python3.8, because the latest version in the default repositories is `python 3.7.3` which won't work for my script.

=== "compile python3.8 from sources"
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

=== "install python3.8 from debian/testing"
    !!! warning "Warning"
        Due to the fact that this will add the debian/testing repositories to your system, this might break your system. Do **not** execute this on a productive system!
        `bash echo -e '\n# python3.8\ndeb [arch=amd64] http://deb.debian.org/debian/ testing main' \ | sudo tee -a /etc/apt/sources.list echo 'APT::Default-Release "stable";' \ | sudo tee /etc/apt/apt.conf.d/99defaultrelease sudo apt update sudo apt install -y -t testing python3.8 python3-pip `
    
    Afterwards you can clone the [pybackup repository](https://github.com/felbinger/pybackup) to a place which is only writeable by root (I recommend `/root/`) and install the reqirements from the `requirements.txt`:
    
    !!! warning "Security Warning"
        Due to the fact that the backup.py will be executed by root cronjob, the file should be only editable by root. Otherwise a lower privileged user, might exchange the python file or add a path (e.g. `/etc/shadow`) to the backup configuration to gain higher privileges ([Privilege Escalation](https://en.wikipedia.org/wiki/Privilege_escalation)).

```bash
# install git and clone repository
sudo apt install -y git
sudo git clone https://github.com/felbinger/pybackup /root/pybackup/
sudo pip3 install -r /root/pybackup/requirements.txt

# delete offside backup cause we don't need it on the server
rm -r /root/pybackup/OffsideBackup

# configure pybackup
vim /root/pybackup/.config.json

# run backup
$ python3.8 backup.py -df
```

I really suggest creating a separate database user which can only create backups.  
Checkout the documentation for your dbms:

- [MariaDB](https://mariadb.com/kb/en/create-user/)
  ```bash
  # example for mariadb (you need SELECT and LOCK TABLES permissions)
  $ sudo docker-compose exec mariadb 'mysql -u root -pSECRET_PASSWORD'
  mariadb> CREATE USER 'backup'@'localhost' IDENTIFIED BY 'SECRET_PASSWORD_FOR_BACKUP';
  mariadb> GRANT SELECT, LOCK TABLES ON mysql.* TO 'backup'@'localhost';
  # add privileges to all databases that you want to backup!
  mariadb> FLUSH PRIVILEGES;
  mariadb> EXIT;
  ```
- [PostgreSQL](https://www.postgresql.org/docs/8.0/sql-createuser.html)
- [MongoDB](https://docs.mongodb.com/manual/reference/method/db.createUser/)

Backups should also be scheduled using cronjob:

```
# database / file backups at 2:50 / 3 am am every every day
00 03 * * * /usr/bin/python3.8 /root/pybackup/backup.py -c /root/pybackup/.config.json -f
50 02 * * * /usr/bin/python3.8 /root/pybackup/backup.py -c /root/pybackup/.config.json -d
```
