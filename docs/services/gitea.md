# Gitea

```yaml
version: '3.9'

services:
  gitea:
    image: gitea/gitea         
    restart: always
    ports:
      - "[::1]:8000:3000"
      - "22222:22"
    volumes:
      - "/srv/gitea:/data"
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:3000"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_gitea.loadbalancer.server.port=3000"
          - "traefik.http.routers.r_gitea.rule=Host(`gitea.domain.de`)"
          - "traefik.http.routers.r_gitea.entrypoints=websecure"
    ```

## OpenID/KeyCloak
* Server Settings -> `Authentication Sources` -> OAuth2 -> OpenID-Connect
* Discovery URL: `https://id.domain.de/auth/realms/<realm>/.well-known/openid-configuration`
