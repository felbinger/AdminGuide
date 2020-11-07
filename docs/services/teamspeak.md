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
      - "/srv/main/ts3/data:/var/ts3server/"
    ports:
      - '2008:2008'      # accounting port
      - '2010:2010/udp'  # weblist port
      - '9987:9987/udp'  # default port (voice)
      - '30033:30033'    # filetransfer port
      - '41144:41144'    # tsdns port
    networks:
      - database
      - default

  sinusbot:
    image: sinusbot/docker
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_sinusbot.loadbalancer.server.port=8087"
      - "traefik.http.routers.r_sinusbot.rule=Host(`sinusbot.domain.de`)"
      - "traefik.http.routers.r_sinusbot.entrypoints=websecure"
      - "traefik.http.routers.r_sinusbot.tls=true"
      - "traefik.http.routers.r_sinusbot.tls.certresolver=myresolver"
    volumes:
      - /srv/main/sinusbot/scripts:/opt/sinusbot/scripts
      - /srv/main/sinusbot/data:/opt/sinusbot/data
    networks:
      - proxy
```
