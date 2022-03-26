# Vaultwarden

```yaml
version: '3.9'

services:
  vaultwarden:
    image: vaultwarden/server:alpine
    restart: always
    env_file: .vaultwarden.env
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/vaultwarden:/data/"
```

```shell
# .vaultwarden.env
DOMAIN=https://vault.secshell.net
SIGNUPS_ALLOWED=false
INVITATIONS_ALLOWED=false
SHOW_PASSWORD_HINT=false
```