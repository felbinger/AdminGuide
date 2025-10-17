# Arma 3 Server

Ein Arma 3 Gameserver ermöglicht es Arma 3 Spielern eine gemeinsame Mission zu spielen.
Das hier beschriebene Vorgehen erweitert die Grundfunktionalität von LGSM (Linux Game Server
Manager) um die benötigten Paketen für extdb2/extdb3.

```yaml
services:
  arma3:
    image: ghcr.io/felbinger/arma3server
    restart: always
    env_file: .arma3.env
    ports:
      - "2302:2302/udp"    # Arma 3 + voice over network
      - "2303:2303/udp"    # Steam Query
      - "2304:2304/udp"    # Steam Master
      - "2305:2305/udp"    # old Voice over Network
      - "2306:2306/udp"    # BattleEye
    volumes:
      - "/srv/arma3:/home/linuxgsm"

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
```sh
# .arma3.env
# will also be stored on filesystem (/srv/aram3/lgsm/config-lgsm/arma3server/arma3server.cfg) during installation!
STEAM_USER=steam_username
STEAM_PASS=steam_password
```

Vor dem ersten Start müssen die Berechtigungen des Verzeichnisses `/srv/arma3` angepasst werden.
```shell
mkdir /srv/arma3
chown 1000:1000 /srv/arma3
```

Anschließend können die Container gestartet werden (`docker compose up -d arma3`),
wodurch die Installation angestoßen wird.

### Wichtige Pfade
```shell
# things that need to be done to start the server (e. g. mods)
/srv/arma3/lgsm/config-lgsm/arma3server/arma3server.cfg

# arma 3 server / network config
/srv/arma3/serverfiles/cfg/arma3server.server.cfg
/srv/arma3/serverfiles/cfg/arma3server.network.cfg

# mpmission folder
/srv/arma3/serverfiles/mpmissions
```

## Exile Mod

Für Exile müssen nun einige Mods im Verzeichnis `/srv/arma3/serverfiles/` hinzugefügt werden:
```shell
cd /srv/arma3/serverfiles/

# download and extract mods
wget https://bravofoxtrotcompany.com/exile/@Exile-1.0.4.zip
wget https://exilemod.com/ExileServer-1.0.4a.zip
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
rm -r /srv/arma3/serverfiles/{Arma\ 3\ Server,MySQL}/

# adjust permissions, so that LGSM can work with all files
chown -R 1000:1000 /srv/arma3
```

Nach einem Neustart der Container (`docker compose down && docker compose up -d`)
sollten diese geladen werden, falls Probleme auftreten können diese dem Serverlog
entnommen werden (`docker compose exec arma3 arma3server console`).

<!--
### Mod: Extended Base Mod
Die Datei `/srv/arma3/lgsm/config-lgsm/arma3server/arma3server.cfg` muss in der Zeile `mods=` um `;@Extended_Base_Mod` erweitert werden.

siehe https://www.youtube.com/watch?v=dhT6C4PrCrQ
-->

### Mod: AdminToolkit
1. [Git-Repository](https://github.com/ole1986/a3-admintoolkit) herunterladen
2. Mittels [PBO-Manager](https://github.com/SteezCram/Armaholic-Archive/tree/main/PBO_Manager) `/a3-admintoolkit-master/@AdminToolkitServer/addons/admintoolkit_servercfg.pbo` entpacken
3. Variablen in `config.cpp` anpassen (siehe `class AdminToolkit` in `class CfgSettings`):
  - ServerCommandPassword
  - AdminList
  - ModeratorList
4. PBO mit modifizierter `config.cpp` packen und @AdminToolkitServer auf den Server hochladen.
5. mission anpassen
    1. Mission entpacken
    2. `/a3-admintoolkit-master/source/mission_file/atk` in root-Verzeichnis der Mission kopieren
    3. Vor `class CfgExileCustomCode` folgende `class CfgAdminToolkitCustomMod` einfügen:
        ```cpp
        class CfgAdminToolkitCustomMod {
          /* Exclude some main menu items
          * To only show the menus loaded from an extension, use:
          *
          * ExcludeMenu[] = {"Players", "Vehicles", "Weapons" , "Other"};
          */
          ExcludeMenu[] = {};

          /* Load an additional sqf file as MOD */
          Extensions[] = {
            /**
            * Usage: {"<Your Mod Title>", "<YourModFile>"}
            * add a new menu entry called My Extension into main menu */
            {"My Extension", "MyExtension"}
          };

          /* 4 Quick buttons allowing to add any action you want - See example below*/
          QuickButtons[] = {
            /* send a message to everyone using the parameter text field */
            {"Restart Msg", "['messageperm', ['Server Restart in X minutes']] call AdminToolkit_doAction"},
            /* Quickly get a Helicopter */
            {"Heli", "['getvehicle', ['B_Heli_Light_01_armed_F']] call AdminToolkit_doAction"},
            /*4 button*/
            {"Empty", "['Command', ['Variable #1', 'Variable #2']] call AdminToolkit_doAction"}
          };
        };
        ```

    4. `description.ext` bearbeiten, Nachfolgendes zur `class CfgRemoteExec.Functions` hinzufügen:
    ```cpp
    class AdminToolkit_network_receiveRequest {
      allowedTargets = 2;
    };
    ```
    5. Mission packen und auf Server hochladen

6. @AdminToolkitServer als Client(!) Mod zur Serverkonfiguration (`/srv/arma3/lgsm/config-lgsm/arma3server/arma3server.cfg`) hinzufügen
    ```
    mods="@Exile;@AdminToolkitServer"
    servermods="@ExileServer"
    ```

8. `verifySignatures` in `serverfiles/cfg/arma3server.server.cfg` deaktivieren, da die Mod nicht signiert ist.

9. Server Neustarten und testen
    ```sh
    docker compose -f /home/admin/arma3/docker-compose.yml down
    docker compose -f /home/admin/arma3/docker-compose.yml up -d
    ```

    Client mit @AdminToolkit Mod starten und dem Spiel beitreten.

    Das AdminInterface sollte auf der Taste F2 liegen.

<!--
### Mod: DMS with "Capture point" missions

siehe https://youtube.com/watch?v=4syLDu9lIrM
siehe https://youtube.com/watch?v=z24natBw37c
-->