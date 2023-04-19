# Calibre

Calibre ist ein Programm zur Verarbeitung, Konvertierung und Verwaltung von E-Books.

```yaml
version: '3.9'

services:
  calibre:
    image: linuxserver/calibre-web
    restart: always
    environment:
      - "PUID=1000"
      - "PGID=1000"
      - "SET_CONTAINER_TIMEZONE=true"
      - "CONTAINER_TIMEZONE=Europe/Berlin"
      - "USE_CONFIG_DIR=true"
    ports:
      - "[::1]:8000:8083"
    volumes:
      - "/srv/calibre/config:/config"
      - "/srv/calibre/books:/books"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8083"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_calibre.loadbalancer.server.port=8083"
          - "traefik.http.routers.r_calibre.rule=Host(`calibre.domain.de`)"
          - "traefik.http.routers.r_calibre.entrypoints=websecure"
    ```