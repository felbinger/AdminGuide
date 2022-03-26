# Gitea

```yaml
  gitea:
    image: gitea/gitea:latest         
    restart: always
    ports:
      - "[::1]:8000:3000"
      - "22222:22"
    volumes:
      - "/srv/gitea:/data"
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
```

## OpenID/KeyCloak
* Server Settings -> `Authentication Sources` -> OAuth2 -> OpenID-Connect
* Discovery URL: `https://id.domain.de/auth/realms/<realm>/.well-known/openid-configuration`
