# Privatebin

[privatebin website](https://privatebin.net/)
[privatebin on dockerhub](https://hub.docker.com/r/privatebin/nginx-fpm-alpine)  

```yaml
  privatebin:
    image: privatebin/nginx-fpm-alpine:latest
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_privatebin.loadbalancer.server.port=8080"
      - "traefik.http.routers.r_privatebin.rule=Host(`privatebin.secshell.net`)"
      - "traefik.http.routers.r_privatebin.entrypoints=websecure"
      - "traefik.http.routers.r_privatebin.tls.certresolver=myresolver"
    volumes:
      - "/srv/storage/privatebin/data:/srv/data"
    networks:
      - proxy
```