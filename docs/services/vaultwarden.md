# Vaultwarden

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
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
      - "DOMAIN=https://vault.secshell.net"
      - "SIGNUPS_ALLOWED=false"
      - "INVITATIONS_ALLOWED=false"
      - "SHOW_PASSWORD_HINT=false"
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/vaultwarden/data:/data/"
```

```shell
# .postgres.env
POSTGRES_PASSWORD=pgSecret
```

```shell
# .vaultwarden.env
DATABASE_URL=postgresql://vaultwarden:pgSecret@postgres/vaultwarden
```