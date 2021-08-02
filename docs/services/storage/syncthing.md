# Syncthing

Checkout the [documentation](https://github.com/syncthing/syncthing/blob/main/README-Docker.md)
```yml
  syncthing:
    image: syncthing/syncthing
    restart: always
    volumes:
      - "/srv/storage/syncthing:/var/syncthing"
    ports:
      - "22000:22000"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_syncthing.loadbalancer.server.port=8384"
      - "traefik.http.routers.r_syncthing.rule=Host(`sync.domain.de`)"
      - "traefik.http.routers.r_syncthing.entrypoints=websecure"
      - "traefik.http.routers.r_syncthing.tls.certresolver=myresolver"
    networks:
      - proxy
```