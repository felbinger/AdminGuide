# Synapse Admin

```yaml 
  synapse-admin: 
    image: awesometechnologies/synapse-admin:0.7.0
    restart: always
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_synapse-admin.loadbalancer.server.port=80"
      - "traefik.http.routers.r_synapse-admin.rule=Host(`matrix-admin.domain.de`)"
      - "traefik.http.routers.r_synapse-admin.entrypoints=websecure"
      - "traefik.http.routers.r_synapse-admin.tls=true"
      - "traefik.http.routers.r_synapse-admin.tls.certresolver=myresolver"   
```

At the time of writing this guide, there is a bug in synapse-admin, so version 0.7.0 is used here to avoid this bug.