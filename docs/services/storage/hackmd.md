# HackMD

[hackmd website](https://hackmd.io/)
[hackmd on dockerhub](https://hub.docker.com/r/hackmdio/hackmd/)  
```yaml
  hackmd:
    image: hackmdio/hackmd
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_hackmd.loadbalancer.server.port=3000"
      - "traefik.http.routers.r_hackmd.rule=Host(`md.domain.de`)"
      - "traefik.http.routers.r_hackmd.entrypoints=websecure"
      - "traefik.http.routers.r_hackmd.tls=true"
      - "traefik.http.routers.r_hackmd.tls.certresolver=myresolver"
    environment:
      - "CMD_DB_URL=mysql://hackmd:S3cr3T@mariadb/hackmd"
    networks:
      - proxy
      - database
```
