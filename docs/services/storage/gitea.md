# Gitea

1. Add the following to your `docker-compose.yml`
2. Start the service (`docker-compose up -d`)
3. Go to the configured domain to install gitea (e.g. configure db setup)

```yaml
  gitea:
    image: gitea/gitea:latest         
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_gitea.loadbalancer.server.port=3000"
      - "traefik.http.routers.r_gitea.rule=Host(`git.domain.de`)"
      - "traefik.http.routers.r_gitea.entrypoints=websecure"
      - "traefik.http.routers.r_gitea.tls=true"
      - "traefik.http.routers.r_gitea.tls.certresolver=myresolver"
    volumes:
      - "/srv/storage/gitea:/data"
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
    ports:
      - "22222:22"
    networks:
      - default
      - proxy
      - database
```

## OpenID/KeyCloak
* Server Settings -> `Authentication Sources` -> OAuth2 -> OpenID-Connect
* Discovery URL: `https://id.domain.de/auth/realms/<realm>/.well-known/openid-configuration`
