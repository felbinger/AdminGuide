Keycloak is an idendety management system. It provides support for OAuth2, OpenID-Connect and Saml2. In other words: You have one account for all of your services.
<br>

The realm is e.g. the name if your organisation. You have to create the realm later in the keycloak admin interface.

```yaml
  keycloak:
    image: jboss/keycloak:<version> # current: 13.0.0, in the future: ghcr.io/an2ic3/keycloak:<version>
    restart: always
    env_file: .keycloak.env
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_keycloak.loadbalancer.server.port=8080"

      - "traefik.http.routers.r_keycloak.rule=Host(`id.<domain>`)" # <- edit (user interface)
      - "traefik.http.routers.r_keycloak.entrypoints=websecure"
      - "traefik.http.middlewares.mw_keycloak-host-rewrite.headers.customrequestheaders.Host=id.<domain>" # <- edit
      - "traefik.http.middlewares.mw_keycloak-host-rewrite2.headers.customrequestheaders.X-Forwarded-Host=id.<domain>" # <- edit
      - "traefik.http.middlewares.mw_keycloak-redirect.replacepathregex.regex=^\/auth\/$$"
      - "traefik.http.middlewares.mw_keycloak-redirect.replacepathregex.replacement=/auth/realms/<ralm>/account/" # <- edit
      - "traefik.http.middlewares.mw_keycloak-block-admin.replacepathregex.regex=^\/auth\/admin\/$$"
      - "traefik.http.middlewares.mw_keycloak-block-admin.replacepathregex.replacement=/auth/realms/<ralm>/account/" # <- edit
      - "traefik.http.routers.r_keycloak.middlewares=mw_keycloak-redirect@docker,mw_keycloak-block-admin@docker,mw_keycloak-host-rewrite@docker,mw_keycloak-host-rewrite2@docker"

      - "traefik.http.routers.r_keycloak-admin.rule=Host(`keycloak.<domain>`)" # <- edit (admin interface)
      - "traefik.http.routers.r_keycloak-admin.entrypoints=websecure"
      - "traefik.http.middlewares.mw_keycloak-admin-redirect.redirectregex.regex=^https:\/\/keycloak.<domain>\/?$$" # <- edit
      - "traefik.http.middlewares.mw_keycloak-admin-redirect.redirectregex.replacement=https://keycloak.<domain>/auth/admin/" # <- edit
      - "traefik.http.routers.r_keycloak-admin.middlewares=mw_keycloak-admin-redirect@docker"
    volumes:
      - "/srv/main/keycloak/extensions:/opt/jboss/keycloak/standalone/deployments"
      - "/etc/localtime:/etc/localtime:ro"
    networks:
      - database
      - proxy
```
## Initial Setup

Open the admin interface (`keycloak.<domain>`) and create a new realm withe the same name as in the docker compose.

![image](https://user-images.githubusercontent.com/34819524/118363751-35f67c00-b596-11eb-9603-95df4a3c8e41.png)

On the left side:

* Realm Settings: Settings for your environment
* Clients: A client is a service witch should be connected with keycloak.
* Identity Providers: Here you can enable that users can login using external services like Google or Twitter.
* Groupes: Roles are global roles that can grant access to other client specific roles.
* Users: Here you can manage your userbase. (e.g. add new users, request a password change and more)

## Add Services
How you can add a service is described on the corresponding page of this service.
