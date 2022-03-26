# Vaultwarden

```yaml
  vaultwarden:
    image: vaultwarden/server:alpine
    restart: always
    environment:
      - "DOMAIN=https://vault.secshell.net"
      - "SIGNUPS_ALLOWED=false"
      - "INVITATIONS_ALLOWED=false"
      - "SHOW_PASSWORD_HINT=false"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_vaultwarden.loadbalancer.server.port=80"
      - "traefik.http.routers.r_vaultwarden.rule=Host(`vaultwarden.domain.de`)"
      - "traefik.http.routers.r_vaultwarden.entrypoints=websecure"
      - "traefik.http.routers.r_vaultwarden.tls=true"
      - "traefik.http.routers.r_vaultwarden.tls.certresolver=myresolver"
    volumes:
      - "/srv/vaultwarden:/data/"
```