# Vaultwarden

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:15
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=vaultwarden"
      - "POSTGRES_USER=vaultwarden"
    volumes:
      - "/srv/vaultwarden/postgres:/var/lib/postgresql/data"

  vaultwarden:
    image: vaultwarden/server:alpine
    restart: always
    env_file: .vaultwarden.env
    environment:
      - "DOMAIN=https://vault.domain.de"
      - "SIGNUPS_ALLOWED=false"
      - "INVITATIONS_ALLOWED=false"
      - "SHOW_PASSWORD_HINT=false"
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/vaultwarden/data:/data/"
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
          - "traefik.http.services.srv_vaultwarden.loadbalancer.server.port=80"
          - "traefik.http.routers.r_vaultwarden.rule=Host(`vaultwarden.domain.de`)"
          - "traefik.http.routers.r_vaultwarden.entrypoints=websecure"
    ```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .vaultwarden.env
DATABASE_URL=postgresql://vaultwarden:S3cr3T@postgres/vaultwarden
```