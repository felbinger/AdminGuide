# Admin Guide

## Install Basic Software
```bash
apt-get update
apt-get -y dist-upgrade
apt-get -y install apt sudo curl nano
```

## Create `admin` group
```bash
groupadd -g 997 admin
mkdir /home/admin
chown -R root:admin /home/admin
chmod -R 775 /home/admin
```

## Create Users
You should create at least one user account, and use it instead of the `root` user.
Let's create a new user called `user` add add him to the groups `sudo` and `admin`.
```bash
adduser user
usermod -aG sudo,admin user
```

### Add SSH Public Key's of the users to there home directories
There are multiple options to add public keys to the file `~/.ssh/authorized_keys`.
One option is to run `ssh-copy-id user@ip` on the client machine (and authenticate yourself with for example a password)
and the ssh client automatically copy the keys there.  
Another options is to append your public key manually to the `~/.ssh/authorized_keys` file in the following format  `ssh-type public_key [description]`:
```bash
# example for an rsa key:
echo "ssh-rsa AAAAB... my_computer" >> ~/.ssh/authorized_keys
```
The description of your public key is stored after the key in the file of that public key on your machine.
`ssh-copy-id` uses the description of your public key, but you can ignore it, if you add your public key manually.

## Configure DNS
```bash
@ A 123.123.123.123                             # redirect domain.tld to ip
* A 123.123.123.123                             # redirect all subdomain to ip
@ CAA 0 issue "letsencrypt.org"                 # allow letsencrypt.org to create certificates for your domain  
@ CAA 0 iodef "mailto:monitoring@domain.tld"    # set email address for certificate status information
```

### Configure reverse DNS
The reverse DNS is used to get the domain which is attached to an ip address.
You can do this in the server control panel.

### Validate DNS updates
DNS Updates can take quiet some time!
```sh
$ dig A domain.tld @1.1.1.1
...
;; ANSWER SECTION:
domain.tld.	86400	IN	A	123.123.123.123
...

$ dig A nonexisting.domain.tld @1.1.1.1
...
;; ANSWER SECTION:
nonexisting.domain.tld.	86400	IN	A	123.123.123.123
...


$ dig CAA domain.tld @1.1.1.1
...
;; ANSWER SECTION:
domain.tld.	86400	IN	CAA	0 iodef "mailto:monitoring@domain.tld"
domain.tld.	86400	IN	CAA	0 issue "letsencrypt.org"
...

$ nslookup 123.123.123.123
123.123.123.123.in-addr.arpa	name = domain.tld.
```

## Change Hostname
In most cases, your hosting provider gave your machine an ugly hostname, so let's change that.
Just write your new hostname to the file `/etc/hostname`.
Then change `/etc/hosts` according to the following example:
```bash
127.0.0.1	      localhost
127.0.1.1	      fqdn.domain.tld server        # <--
123.123.123.123	      fqdn.domain.tld server        # <--

# The following lines are desirable for IPv6 capable hosts
::1                localhost ip6-localhost ip6-loopback
ff02::1            ip6-allnodes
ff02::2            ip6-allrouters
```
In this case I decided to use the hostname `server` and assign the fully qualified domain name `fqdn.domain.tld` to it.
To apply the changes, you need to restart the server.

## Configure SSH
After we successfully logged in using one of our user accounts, we can reconfigure ssh. We set `PasswordAuthentication` and `PermitRootLogin` to `no`.

**Warning**: Make sure you can login using your SSH private key, otherwise you are not able to login again after the next step!

## Install Docker
```bash
curl https://get.docker.com | sudo bash
sudo curl -L -o /usr/local/bin/docker-compose \
  "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" 
sudo chmod +x /usr/local/bin/docker-compose
```

## Create Stack Logic
We will group the services in different "stacks" to manage them, this way we can change specific things without taking all services offline. Furthermore we will use one docker network per stack to make sure, that each container is only able to communicate with other containers which it really needs.

First, let's add the default directories into the admin directory:
```bash
mkdir -p /home/admin/{services,images,tools,docs}/
```

For each stack we will create, we want to have a directory in `/home/admin/services/`, `/home/admin/images/` and `/srv/`:
* The directory in `/home/admin/services/` contains the `docker-compose.yml` and `.env` files. The latter is used in the `docker-compose.yml` as `env_file`.
* The directory in `/home/admin/images/` contains the source files for the docker image if we have to build the image on the server.
* The directory in `/srv/` is used to store persistent data for the stack (docker volumes).

We will also create multiple docker networks, to give the containers the ability to communicate with each other.
* Helper networks (for communitation between diffrent stacks: e.g. database, proxy, monitoring, ...) start at `192.168.0.0/24`
* Stack networks (one network for each stack) start at `192.168.100.0/24`

Remember that a network with the submask 255.255.255.0 (cidr notation is 24) can only contain 254 hosts. You have to adjust your network size to your needs.  

Remember the formular: `2^(32−x)−2` where `x` is your submask in cidr notation  
(e.g. with 24: `2^(32−24)−2=254`; or with 20: `2^(32−20)−2=4094` usable adresses)

|    Name    |      Subnet      |                            Usage                           |
|:-----------|:-----------------|:-----------------------------------------------------------|
| Proxy      | 192.168.0.0/24   | Container communiation to nginx reverse proxy.             |
| Database   | 192.168.1.0/24   | Communication to databases (MariaDB, MongoDB, PostgreSQL). |
| Monitoring | 192.168.2.0/24   | Communication to monitoring utilities (InfluxDB).          |
|            |                  |                                                            |
| Main       | 192.168.100.0/24 | Network for the Main Stack                                 |
|            |                  |                                                            ||

```bash
# create main stack
name='main'
mkdir -p "/home/admin/{services,images}/${name}/"
sudo mkdir -p "/srv/${name}/"
sudo docker network create --subnet 192.168.100.0/24 ${name}

# create helper networks (we will need them in the next chapter)
sudo docker network create --subnet 192.168.0.0/24 proxy
sudo docker network create --subnet 192.168.1.0/24 database
sudo docker network create --subnet 192.168.2.0/24 monitoring
```

Lastly we are going to create a `docker-compose.yml` which we will use to define our networks.
```yaml
version: '3'
services:
  ...

networks:
  default:
    external:
      name: main
  proxy:
    external:
      name: proxy
  database:
    external:
      name: database
  monitoring:
    external:
      name: monitoring
```
The network created for a particular stack will be called `default` in the matching `docker-compose.yml`.
This will help us, because if we do not specify a network in the service sections of the `docker-compose.yml`, these services will automatically connectto network `defalut`.

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
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.3/ctop-0.7.3-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
```

### Docker Network Viewer
A simple tool to show docker networks:
```
sudo wget https://github.com/felbinger/DNV/releases/download/v0.1/dnv -O /home/admin/tools/dnv
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
sudo apt-get install build-essential checkinstall libreadline-gplv2-dev libncursesw5-dev \
  libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev
  
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
