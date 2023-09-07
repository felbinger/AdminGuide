# Minecraft Server

Ein Spigot Server, welcher auch den Zugriff auf Mods erlaubt.

```yaml
version: '3.9'

services:
  minecraft:
    image: itzg/minecraft-server
    restart: always
    ports:
      - '25565:25565'
    volumes:
      - '/srv/minecraft:/data'
    environment:
      - "TYPE=SPIGOT"
      - "SPIGOT_DOWNLOAD_URL=https://cdn.getbukkit.org/spigot/spigot-1.16.3.jar"
      - "OVERRIDE_SERVER_PROPERTIES=true"
      - "EULA=TRUE"
      - "MAX_PLAYERS=50"
      - "TZ=Europe/Berlin"
      - "MAX_MEMORY=8G"
      - "MAX_RAM=8G"
      - "MIN_RAM=4G"
      - "ENABLE_AUTOPAUSE=TRUE"
      - "MOTD=checkout https://adminguide.pages.dev/"
      - "SPAWN_PROTECTION=0"
      - "SEED=2303273916051849791"
```