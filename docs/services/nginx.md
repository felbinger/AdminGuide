# nginx

```yaml
version: '3.9'

services:
  homepage:
    image: nginx
    restart: always
    ports:
      - "[::1]:8000:80" 
    volumes:
      - "/srv/homepage:/usr/share/nginx/html/"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_homepage.loadbalancer.server.port=80"
          - "traefik.http.routers.r_homepage.rule=Host(`homepage.domain.de`)"
          - "traefik.http.routers.r_homepage.entrypoints=websecure"
    ```