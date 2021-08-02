# Calibre

checkout [linuxserver/calibre](https://hub.docker.com/r/linuxserver/calibre)
```yaml
  calibre:
    image: linuxserver/calibre-web
    restart: always
    environment:
      - "PUID=1000"
      - "PGID=1000"
      - "SET_CONTAINER_TIMEZONE=true"
      - "CONTAINER_TIMEZONE=Europe/Berlin"
      - "USE_CONFIG_DIR=true"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_calibre.loadbalancer.server.port=8083"
      - "traefik.http.routers.r_calibre.rule=Host(`calibre.domain.de`)"
      - "traefik.http.routers.r_calibre.entrypoints=websecure"
      - "traefik.http.routers.r_calibre.tls.certresolver=myresolver"
    volumes:
      - "/srv/storage/calibre/config:/config"
      - "/srv/storage/calibre/books:/books"
    networks:
      - proxy
      - database
```