# TeamSpeak

```yaml
version: '3.9'

services:
  mariadb:
    image: mariadb
    restart: always
    env_file: .mariadb.env
    environment:
      - "MYSQL_RANDOM_ROOT_PASSWORD=yes"
      - "MYSQL_DATABASE=teamspeak"
      - "MYSQL_USER=teamspeak"
    volumes:
      - "/srv/teamspeak3/mariadb:/var/lib/mysql"
  
  teamspeak3:
    image: teamspeak
    restart: always
    env_file: .teamspeak3.env
    environment:
      - "TS3SERVER_DB_PLUGIN=ts3db_mariadb"
      - "TS3SERVER_DB_USER=teamspeak"
      - "TS3SERVER_DB_NAME=teamspeak"
      - "TS3SERVER_DB_SQLCREATEPATH=create_mariadb"
      - "TS3SERVER_DB_HOST=mariadb"
      - "TS3SERVER_DB_WAITUNTILREADY=30"
      - "TS3SERVER_LICENSE=accept"
    volumes:
      - "/srv/teamspeak3/data:/var/ts3server/"
    ports:
      - '9987:9987/udp'  # voice
      - '30033:30033'    # filetransfer

  sinusbot:
    image: sinusbot/docker
    restart: always
    ports:
      - "[::1]:8000:8087"
    volumes:
      - "/srv/sinusbot/scripts:/opt/sinusbot/scripts"
      - "/srv/sinusbot/data:/opt/sinusbot/data"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8087"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_sinusbot.loadbalancer.server.port=8087"
          - "traefik.http.routers.r_sinusbot.rule=Host(`sinusbot.domain.de`)"
          - "traefik.http.routers.r_sinusbot.entrypoints=websecure"
    ```

```shell
# .mariadb.env
MYSQL_PASSWORD=S3cr3T
```

```shell
# .teamspeak3.env
TS3SERVER_DB_PASSWORD=S3cr3t
```

After the first start of the containers, the root password for mariadb, the server query credentials 
and the teamspeak privilege token will be printed out to the docker logs of the mariadb / teamspeak container.
Make sure to save them in a safe place.

### Reset server query admin password
If you forgot your server query admin password you can reset it using the following command:

```shell
sudo docker-compose run --rm teamspeak3 ts3server inifile=/var/run/ts3server/ts3server.ini serveradmin_password=NEW_PASSWORD
```

Afterwards you can connect to port 10011 using telnet or netcat to generate for example new privilege tokens:
```sh
nc localhost 10011
login serveradmin NEW_PASSWORD
# use server 1 (default)
use 1
# add a new admin token
tokenadd tokentype=0 tokenid1=6 tokenid2=0
```