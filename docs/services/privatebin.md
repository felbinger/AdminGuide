# Privatebin

```yaml
version: '3.9'

services:
  privatebin:
    image: privatebin/nginx-fpm-alpine
    restart: always
    ports:
      - "[::1]:8000:8080"
    volumes:
      - "/srv/privatebin:/srv/data"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8080"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_privatebin.loadbalancer.server.port=8080"
          - "traefik.http.routers.r_privatebin.rule=Host(`privatebin.domain.de`)"
          - "traefik.http.routers.r_privatebin.entrypoints=websecure"
    ```