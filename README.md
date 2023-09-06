# Admin Guide
You can find this repository here: [https://adminguide.pages.dev](https://adminguide.pages.dev).

## Contribute
Feel free to open issues / pull requests.  
Please validate that your changes work as intented!  
You can start the mkdocs development server by running:
```bash
sudo ./serve.sh
# or
sudo sh ./serve.sh
```
The http server is then listening on port 8000.  
**Please review every script from the Internet before executing it!**

### Contribution Guidelines
* Web Services are exposed to `[::1]:8000`
* Secret Environment Variables are in an env_file (and not in the `docker-compose.yml` itself, to prevent leaks) with the following format:
  ```shell
  # .servicename.env
  KEY=value
  ```
* environment variables should be in form of a YAML array, not an object:
  ```yaml
  environment:
    - "KEY=value"
  ```
  instead of
  ```yaml
  # WRONG - please don't do this
  environemnt:
    KEY: value
  # WRONG
  ```
* If possible the service should use either mariadb or postgresql.
  If it makes sense, other databases (e.g. sqlite) are also quiet fine.
* YAML arrays should be quoted, regardless which data is stored:
  ```yaml
  volumes:
    - "/srv/service_name/data:/data"
  ports:
    - "[::1]:8000:1234"
  networks:
    - "default"
    - "database"
  ```

## TODO
### Traefik
* Can traefik assign each http router a separate ipv6 address?
* How to configure authenticated origin pulls with cloudflare?
* Describe for traefik with cloudflare how to use origin server wildcard certificates (instead of using ACME with LEGO):  
  should work like this:
  ```shell
  commands:
    # ...
    - "--tls.certificatesresolvers.myresolver1.acme=false"
    - "--tls.certificatesresolvers.myresolver1.certFile=/certs/domain1.crt"
    - "--tls.certificatesresolvers.myresolver1.keyFile=/certs/domain1.key"
    - "--tls.certificatesresolvers.myresolver1.domains[0]=domain1.com"
    - "--tls.certificatesresolvers.myresolver2.acme=false"
    - "--tls.certificatesresolvers.myresolver2.certFile=/certs/domain2.crt"
    - "--tls.certificatesresolvers.myresolver2.keyFile=/certs/domain2.key"
    - "--tls.certificatesresolvers.myresolver2.domains[0]=domain2.com"
  # ...
  volumes:
    # ...
    - "/srv/traefik/certs:/certs"
  ```
* Test traefik setup - I wrote it from what I remembered last time doing it...
* Think about splitting the three [traefik container definition](./docs/installation/) into separate files (to avoid duplicate configuration fragments).
* Keycloak: Admin Webinterface Protection for Traefik as Reverse Proxy:  
  I found this on an old server - please test this before putting it into admin guide...
  ```yaml
    labels:
      # ...
      - "traefik.http.routers.r_keycloak.rule=Host(`id.domain.de`)" # <- edit (user interface)
      - "traefik.http.routers.r_keycloak.tls=true"
      - "traefik.http.routers.r_keycloak.entrypoints=websecure"
      - "traefik.http.middlewares.mw_keycloak-host-rewrite.headers.customrequestheaders.Host=id.domain.de" # <- edit
      - "traefik.http.middlewares.mw_keycloak-host-rewrite2.headers.customrequestheaders.X-Forwarded-Host=id.domain.de" # <- edit
      - "traefik.http.middlewares.mw_keycloak-redirect.replacepathregex.regex=^\/auth\/$$"
      - "traefik.http.middlewares.mw_keycloak-redirect.replacepathregex.replacement=/auth/realms/main/account/" # <- edit
      - "traefik.http.middlewares.mw_keycloak-block-admin.replacepathregex.regex=^\/auth\/admin\/$$"
      - "traefik.http.middlewares.mw_keycloak-block-admin.replacepathregex.replacement=/auth/realms/master/account/" # <- edit
      - "traefik.http.routers.r_keycloak.middlewares=mw_keycloak-redirect@docker,mw_keycloak-block-admin@docker,mw_keycloak-host-rewrite@docker,mw_keycloak-host-rewrite2@docker"

      - "traefik.http.routers.r_keycloak-admin.rule=Host(`keycloak.domain.de`)" # <- edit (admin interface)
      - "traefik.http.routers.r_keycloak-admin.tls=true"
      - "traefik.http.routers.r_keycloak-admin.entrypoints=websecure"
      - "traefik.http.middlewares.mw_keycloak-admin-redirect.redirectregex.regex=^https:\/\/keycloak.domain.de\/?$$" # <- edit
      - "traefik.http.middlewares.mw_keycloak-admin-redirect.redirectregex.replacement=https://keycloak.domain.de/auth/admin/" # <- edit
      - "traefik.http.routers.r_keycloak-admin.middlewares=mw_keycloak-admin-redirect@docker"

  ```

### Services
#### More
* Monitoring

#### Rewrite required:
* Grafana (configure ldap and oidc using environment files, not via config; external database)
* Netbox
* Guacamole: OIDC Integration (doesn't work like this...)
* Gitea: OIDC
* Bookstack: SAML