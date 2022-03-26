# Minecraft Server
[itzg/minecraft documentation](https://github.com/itzg/docker-minecraft-server/blob/master/README.md)
```yaml
  minecraft:
    image: itzg/minecraft-server
    restart: always
    ports:
      - '25565:25565'
    volumes:
      - '/srv/minecraft:/data'
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
      - 'MOTD=checkout https://felbinger.github.io/AdminGuide/'
      - 'SPAWN_PROTECTION=0'
      - 'SEED=2303273916051849791'
```
