# Syncthing

Software zum verwalten, synchronisieren und versionieren von Dateien.

```yaml
version: '3.9'

services:
  syncthing:
    image: syncthing/syncthing
    restart: always
    volumes:
      - "/srv/syncthing:/var/syncthing"
    ports:
      - "22000:22000"
      - "[::1]:8000:8384"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8384"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_syncthing.loadbalancer.server.port=8384"
          - "traefik.http.routers.r_syncthing.rule=Host(`syncthing.domain.de`)"
          - "traefik.http.routers.r_syncthing.entrypoints=websecure"
    ```