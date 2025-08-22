# Arma 3 Server

Ein Arma 3 Gameserver ermöglicht es Arma 3 Spielern eine
gemeinsame Mission zu spielen. Das hier beschriebene Vorgehen
erweitert die Grundfunktionalität von LGSM (Linux Game Server
Manager) um die benötigten Paketen für extdb3.

In diesem Beispiel wird ein Arma 3 Exile Mod Server aufgesetzt:

```yaml
services:
  arma3:
    image: ghcr.io/felbinger/arma3server
    restart: always
    environment:
      # will be stored on filesystem during installation:
      # /srv/arma3/lgsm/config-lgsm/arma3server/arma3server.cfg
      - "STEAM_USER="
      - "STEAM_PASS="
    ports:
      - '2302:2302/udp'    # Arma 3 + voice over network
      - '2303:2303/udp'    # Steam Query
      - '2304:2304/udp'    # Steam Master
      - '2305:2305/udp'    # old Voice over Network
      - '2306:2306/udp'    # BattleEye
    volumes:
      - '/srv/arma3:/home/linuxgsm'

  mariadb:
    image: mariadb
    restart: always
    environment:
      - "MARIADB_RANDOM_ROOT_PASSWORD=true"
      - "MARIADB_USER=arma3"
      - "MARIADB_PASSWORD=S3cr3T"
      - "MARIADB_DATABASE=exile"
    volumes:
      - "/srv/arma3-mariadb:/var/lib/mysql"
```

Vor dem ersten Start müssen die Berechtigungen des Verzeichnisses `/srv/arma3` angepasst werden.
```shell
mkdir /srv/arma3
chown 1000:1000 /srv/arma3
```

Anschließend können die Container gestartet werden (`docker compose up -d arma3`),
wodurch die Installation angestoßen wird.

Für Exile müssen nun einige Mods im Verzeichnis `/srv/arma3/serverfiles/` hinzugefügt werden:
```shell
cd /srv/arma3/serverfiles/

# download and extract mods
wget http://bravofoxtrotcompany.com/exile/@Exile-1.0.4.zip
wget http://exilemod.com/ExileServer-1.0.4a.zip
unzip @Exile-1.0.4.zip
unzip ExileServer-1.0.4a.zip
rm *.zip

# move the extracted files into the correct locations
cp -r /srv/arma3/serverfiles/Arma\ 3\ Server/* /srv/arma3/serverfiles/

# create tables on database using provided database schema
docker compose exec -T mariadb \
  mysql -uexile -pexile exile < /srv/arma3/serverfiles/MySQL/exile.sql

# adjust extdb2 configuration
sed -i 's/^IP = 127.0.0.1/IP = mariadb/' /srv/arma3/serverfiles/@ExileServer/extdb-conf.ini
sed -i 's/^Username = changeme/Username = arma3/' /srv/arma3/serverfiles/@ExileServer/extdb-conf.ini
sed -i 's/^Password = /Password = S3cr3T/' /srv/arma3/serverfiles/@ExileServer/extdb-conf.ini

# arma 3 server configs
mv /srv/arma3/serverfiles/@ExileServer/basic.cfg /srv/arma3/serverfiles/cfg/arma3server.network.cfg
mv /srv/arma3/serverfiles/@ExileServer/config.cfg /srv/arma3/serverfiles/cfg/arma3server.server.cfg

# add mods to server startup configuration
cat <<_EOF > /srv/arma3/lgsm/config-lgsm/arma3server/arma3server.cfg
mods="@Exile"
servermods="@ExileServer"
_EOF

# delete remaining extracted files from exile-server
rm -r /srv/arma3/serverfiles/Arma\ 3\ Server/
rm -r /srv/arma3/serverfiles/MySQL
```

Nach einem Neustart der Container (`docker compose down && docker compose up -d`)
sollten diese geladen werden, falls Probleme auftreten können diese dem Serverlog
entnommen werden (`docker compose exec arma3 arma3server console`).

### Wichtige Pfade
```shell
# things that need to be done to start the server (e. g. mods)
/srv/arma3/lgsm/config-lgsm/arma3server/arma3server.cfg

# arma 3 server / network config
/srv/arma3/serverfiles/cfg/arma3server.server.cfg
/srv/arma3/serverfiles/cfg/arma3server.network.cfg
```
