# Minecraft Server
```yml
  minecraft:
    image: itzg/minecraft-server
    restart: always
    ports:
      - '25565:25565'
    volumes:
      - '/srv/games/minecraft:/data'
    environment:
      - 'TYPE=SPIGOT'
      - 'SPIGOT_DOWNLOAD_URL=https://cdn.getbukkit.org/spigot/spigot-1.16.3.jar'
      - 'OVERRIDE_SERVER_PROPERTIES=true'
      - 'EULA=TRUE'
      - 'MAX_PLAYERS=50'
      - 'TZ=Europe/Berlin'
      - 'MAX_MEMORY=8G'
      - 'MAX_RAM=8G'
      - 'MIN_RAM=4G'
      - 'ENABLE_AUTOPAUSE=TRUE'
      - 'MOTD=checkout https://github.com/felbinger/AdminGuide/wiki'
      - 'SPAWN_PROTECTION=0'
      - 'SEED=2303273916051849791'
```

# Linux Game Server Manager: Arma 3 Server

## Create the custom lgsm arma 3 server image
* create `entrypoint.sh`, to start the arma 3 server automaticly:
  ```bash
  #!/bin/bash

  # start arma 3 server if already installed
  if [[ -e /home/linuxgsm/arma3server && -e /home/linuxgsm/serverfiles ]]; then
      ~/arma3server start
  else
      # start the installation process
      cp /linuxgsm.sh ~/linuxgsm.sh
      echo 4 | ~/linuxgsm.sh install
      ~/arma3server install
  fi


  /usr/bin/tmux set -g status off && /usr/bin/tmux attach 2> /dev/null

  tail -f /dev/null

  exit 0
  ```

* create custom `Dockerfile`, which extends the lgsm image:
  ```Dockerfile
  FROM gameservermanagers/linuxgsm-docker

  USER root

  # install libtbb2:i386 for arma 3 extdb3
  RUN dpkg --add-architecture i386 \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y libtbb2:i386 \
    && rm -rf /var/lib/apt/lists/*

  # add custom entrypoint
  COPY entrypoint.sh /entrypoint.sh
  RUN chmod +x /entrypoint.sh

  USER linuxgsm
  ```

* build the custom docker image:
  ```
  sudo docker build -t arma3server .
  ```

## Start the arma3 server
* create service in `docker-compose.yml`:
  ```yml
  arma3:
    image: arma3server
    restart: always
    ports:
      - '2302:2302/udp'    # Arma 3 + voice over network
      - '2303:2303/udp'    # Steam Query
      - '2304:2304/udp'    # Steam Master
      - '2305:2305/udp'    # old Voice over Network
      - '2306:2306/udp'    # BattleEye
    volumes:
      - '/srv/games/arma3:/home/lgsm'
  ```

* start the service and execute a shell:
  ```
  sudo docker-compose up -d arma3
  sudo docker-compose exec arma3 bash
  ```

* add credentials for a steam account (you should create a new one):
  ```
  cat <<EOF >> ~/lgsm/config-lgsm/arma3server/arma3server.cfg
  steamuser="YOUR_USERNMAE"
  steampass='YOUR_PASSWORD'
  EOF
  ```

* start the installation process:
  ```
  ./arma3server install
  ```

  ![first picture of the installation process](./../blob/master/img/arma3_install_1.png?raw=true)
  ![second picture of the installation process](./../blob/master/img/arma3_install_2.png?raw=true)


## configurations
```bash
# things that need to be done to start the server (e. g. mods)
/srv/games/arma3/lgsm/config-lgsm/arma3server/arma3server.cfg

# arma 3 server / network config
/srv/games/arma3/serverfiles/cfg/arma3server.server.cfg
/srv/games/arma3/serverfiles/cfg/arma3server.network.cfg
```
