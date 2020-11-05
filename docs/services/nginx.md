## nginx
Checkout the [documentation]()
```yaml
  homepage:
    image: nginx
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_homepage.loadbalancer.server.port=80"
      - "traefik.http.routers.r_homepage.rule=Host(`phpmyadmin.domain.de`)"
      - "traefik.http.routers.r_homepage.entrypoints=websecure"
      - "traefik.http.routers.r_homepage.tls=true"
      - "traefik.http.routers.r_homepage.tls.certresolver=myresolver"
    volumes:
      - "/srv/main/homepage/webroot:/usr/share/nginx/html/"
    networks:
      - proxy
```