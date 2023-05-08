# Bookstack

Bookstack ist eine einfache Wiki- / KnowledgeBase Software.

```yaml
version: '3.9'

services:
  mariadb:
    image: mariadb
    restart: always
    env_file: .mariadb.env
    environment:
      - "MYSQL_RANDOM_ROOT_PASSWORD=yes"
      - "MYSQL_DATABASE=bookstack"
      - "MYSQL_USER=bookstack"
    volumes:
      - "/srv/bookstack/mariadb:/var/lib/mysql"

  bookstack:
    image: linuxserver/bookstack
    restart: always
    env_file: .bookstack.env
    environment:
      - "DB_HOST=mariadb"
      - "DB_USER=bookstack"
      - "DB_DATABASE=bookstack"
      - "APP_URL=https://bookstack.domain.de"
    volumes:
      - "/srv/bookstack/config:/config"
    ports:
      - "[::1]:8000:80"
```

```shell
# .mariadb.env
MYSQL_PASSWORD=S3cr3T
```

```shell
# .bookstack.env
DB_PASS=S3cr3T
```

=== "nginx"
    ```yaml
    ports:
    - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/bookstack.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name bookstack.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/bookstack.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/bookstack.domain.de_ecc/bookstack.domain.de.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
        ssl_session_tickets off;

        # modern configuration
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers off;

        # HSTS (ngx_http_headers_module is required) (63072000 seconds)
        add_header Strict-Transport-Security "max-age=63072000" always;

        # OCSP stapling
        ssl_stapling on;
        ssl_stapling_verify on;

        location / {
            proxy_pass http://[::1]:8000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    ```

=== "Traefik"
    ```yaml
        labels:
        - "traefik.enable=true"
        - "traefik.http.services.srv_bookstack.loadbalancer.server.port=80"
        - "traefik.http.routers.r_bookstack.rule=Host(`bookstack.domain.de`)"
        - "traefik.http.routers.r_bookstack.entrypoints=websecure"
    ```

Anschließend können Sie sich unter der angegebenen Domain mit den Zugangsdaten `admin@admin.com`:`password` einloggen.

## Setting up SAML2 Authentication

Hier ist eine Anleitung wie man SAML2 Authentifizierung mit einem *Keycloak* Server einrichtet.

Zuerst müssen wir Keycloak konfigurieren.

Erstellt man einen neuen Client mit `https://bookstack.domain.de/saml2/metadata` als Client ID und `saml` als Client
Protokoll, so kann man die Einstellungen des neuen Clients wie folgt bearbeiten.

| Setting                   | Value                           |
|---------------------------|---------------------------------|
| Client Signature Required | OFF                             |
| Root URL                  | `https://bookstack.domain.de/`  |
| Valid Redirect URIs       | `https://bookstack.domain.de/*` |
| Base URL                  | `https://bookstack.domain.de/`  |

Fine Grain SAML Endpoint Konfiguration:

| Setting                                     | Value                                   |
|---------------------------------------------|-----------------------------------------|
| Assertion Consumer Service POST Binding URL | `https://bookstack.domain.de/saml2/acs` |
| Logout Service Redirect Binding URL         | `https://bookstack.domain.de/saml2/sls` |

Wenn man das gespeichert hat, so können wir u den "Mappers"-Tab gehen und einen neuen Mapper wie folgt erstellen:

| Setting                   | Value         |
|---------------------------|---------------|
| Name                      | username      |
| Mapper Type               | user property |
| Property                  | username      |
| Friendly Name             | Username      |
| SAML Attribute Name       | user.username |
| SAML Attribute NameFormat | basic         |

Und noch einen für die Mail:

| Setting                   | Value         |
|---------------------------|---------------|
| Name                      | email         |
| Mapper Type               | user property |
| Property                  | email         |
| Friendly Name             | User Email    |
| SAML Attribute Name       | user.email    |
| SAML Attribute NameFormat | basic         |

Wenn man beide gespeichert hat, sind wir mit der Keycloak Konfiguration fast fertig. Wir müssen nur noch eine folgende
Einstellung bearbeiten:

In `Client Scopes -> role_list -> Mappers -> role list` muss noch die "Single Role Attribute" Einstellung zu "ON"
geändert werden.
Wenn dies gespeichert wurde, ist die Keycloak Konfiguration vollendet.

<br />

Jetzt müssen wir Bookstack konfigurieren. Änder folgende Zeilen in der Datei `YOURCONFIGPATH/www/.env`:

```
# Set authentication method to be saml2
AUTH_METHOD=saml2

# Set the display name to be shown on the login button.
# (Login with <name>)
SAML2_NAME=YOURORGANIZATIONNAME

# Name of the attribute which provides the user's email address
SAML2_EMAIL_ATTRIBUTE=user.email

# Name of the attribute to use as an ID for the SAML user.
SAML2_EXTERNAL_ID_ATTRIBUTE=user.username

# Name of the attribute(s) to use for the user's display name
# Can have mulitple attributes listed, separated with a '|' in which
# case those values will be joined with a space.
# Example: SAML2_DISPLAY_NAME_ATTRIBUTES=firstName|lastName
# Defaults to the ID value if not found.
SAML2_DISPLAY_NAME_ATTRIBUTES=user.username

# Identity Provider entityID URL
SAML2_IDP_ENTITYID=https://keycloak.domain.de/auth/realms/YOURREALM

# Auto-load metatadata from the IDP
# Setting this to true negates the need to specify the next three options
SAML2_AUTOLOAD_METADATA=false

# Identity Provider single-sign-on service URL
# Not required if using the autoload option above.
SAML2_IDP_SSO=https://keycloak.domain.de/auth/realms/YOURREALM/protocol/saml

# Identity Provider single-logout-service URL
# Not required if using the autoload option above.
# Not required if your identity provider does not support SLS.
SAML2_IDP_SLO=https://keycloak.domain.de/auth/realms/YOURREALM/protocol/saml

# Identity Provider x509 public certificate data.
# Not required if using the autoload option above.
SAML2_IDP_x509=YOURCERT
```

Um das x509 public Zertifikat zu bekommen, müssen wir erneut in den Keycloak Admin.
In den `Ream Settings` kann man unter `SAML 2.0 Identity Provider Metadata` das public Zertifikat einsehen. Kopiere es
und füge es in der Datei ein.

<br />

Wenn man jetzt einen `docker compose restart` durchführt sollte es möglich sein sich über Keycloak anzumelden.

Für weitere Dokumentation empfehlen wir die [Offiziellen Docs](https://www.bookstackapp.com/docs/admin/saml2-auth/).