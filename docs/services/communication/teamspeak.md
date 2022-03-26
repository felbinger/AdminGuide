# TeamSpeak

Checkout the [documentation](https://hub.docker.com/_/teamspeak)
```yaml
  ts3:
    image: teamspeak
    restart: always
    environment:
      - "TS3SERVER_DB_PLUGIN=ts3db_mariadb
      - "TS3SERVER_DB_SQLCREATEPATH=create_mariadb
      - "TS3SERVER_DB_HOST=mariadb"
      - "TS3SERVER_DB_USER=teamspeak"
      - "TS3SERVER_DB_PASSWORD=S3cr3t"
      - "TS3SERVER_DB_NAME=teamspeak"
      - "TS3SERVER_DB_WAITUNTILREADY=30"
      - "TS3SERVER_LICENSE=accept"
    volumes:
      - "/srv/ts3:/var/ts3server/"
    ports:
      - '2008:2008'      # accounting port
      - '2010:2010/udp'  # weblist port
      - '9987:9987/udp'  # default port (voice)
      - '30033:30033'    # filetransfer port
      - '41144:41144'    # tsdns port

  sinusbot:
    image: sinusbot/docker
    restart: always
    ports:
      - "[::1]:8000:8087"
    volumes:
      - /srv/sinusbot/scripts:/opt/sinusbot/scripts
      - /srv/sinusbot/data:/opt/sinusbot/data
```

If you forgot your serverquery admin password you can reset it using the following command:

!!! note ""
    If you configured the environment variables inside an env file you can use: `--env-file .ts3server.env`

```
sudo docker run --rm -it \
  -e TS3SERVER_DB_PLUGIN=ts3db_mariadb \
  -e TS3SERVER_DB_SQLCREATEPATH=create_mariadb \
  -e TS3SERVER_DB_HOST=mariadb \
  -e TS3SERVER_DB_USER=teamspeak \
  -e TS3SERVER_DB_NAME=teamspeak \
  -e TS3SERVER_DB_PASSWORD=S3cr3t \
  -e TS3SERVER_DB_WAITUNTILREADY=30 \
  -e TS3SERVER_LICENSE=accept \
  -v "/srv/ts3/data:/var/ts3server/" \
  --network ts3 \
  teamspeak \
  ts3server inifile=/var/run/ts3server/ts3server.ini serveradmin_password=NEW_PASSWORD
```

Afterwards you can connect to port 10011 using telnet or netcat
```sh
nc localhost 10011
login serveradmin NEW_PASSWORD
# use server 1 (default)
use 1
# add a new admin token
tokenadd tokentype=0 tokenid1=6 tokenid2=0
```