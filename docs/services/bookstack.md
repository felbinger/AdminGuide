# Bookstack

Bookstack verwendet die Idee von Büchern, um Seiten zu organisieren und Informationen zu speichern.

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

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_bookstack.loadbalancer.server.port=80"
          - "traefik.http.routers.r_bookstack.rule=Host(`bookstack.domain.de`)"
          - "traefik.http.routers.r_bookstack.entrypoints=websecure"
    ```

```shell
# .mariadb.env
MYSQL_PASSWORD=S3cr3T
```

```shell
# .bookstack.env
DB_PASS=S3cr3T
```

You should now be able to log in under the given domain. The default credentials are `admin@admin.com`:`password`.

## Setting up SAML2 Authentication

Now here's how to set up SAML2 Authentication with a *Keycloak* Server.

At first, we have to configure Keycloak properly.

Create a new Client. Client ID is `https://bookstack.domain.de/saml2/metadata`, Client Protocol
is `saml`. Now edit the settings of your newly created Client as follows:

| Setting                   | Value                             |
|---------------------------|-----------------------------------|
| Client Signature Required | OFF                               |
| Root URL                  | `https://bookstack.domain.de/`  |
| Valid Redirect URIs       | `https://bookstack.domain.de/*` |
| Base URL                  | `https://bookstack.domain.de/`  |

Fine Grain SAML Endpoint Configuration:

| Setting                                     | Value                                     |
|---------------------------------------------|-------------------------------------------|
| Assertion Consumer Service POST Binding URL | `https://bookstack.domain.de/saml2/acs` |
| Logout Service Redirect Binding URL         | `https://bookstack.domain.de/saml2/sls` |


Save this. Now go to the "Mappers"-Tab. Create a new Mapper:

| Setting                   | Value         |
|---------------------------|---------------|
| Name                      | username      |
| Mapper Type               | user property |
| Property                  | username      |
| Friendly Name             | Username      |
| SAML Attribute Name       | user.username |
| SAML Attribute NameFormat | basic         |


Save this. Create another Mapper:

| Setting                   | Value         |
|---------------------------|---------------|
| Name                      | email         |
| Mapper Type               | user property |
| Property                  | email         |
| Friendly Name             | User Email    |
| SAML Attribute Name       | user.email    |
| SAML Attribute NameFormat | basic         |

Also hit save on this one. Now we are almost done with the Keycloak Config. There is just one
more Setting we need to change, and that is the following:

Go to `Client Scopes -> role_list -> Mappers -> role list` and set "Single Role Attribute" to ON. Save.
Now we have finished the Keycloak Configuration.

<br />

Now we need to do the Configuration of Bookstack. Edit the following File: `YOURCONFIGPATH/www/.env`.
Add the following Lines:

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

To get the x509 public certificate you have to open the Keycloak Admin once again.
In the `Realm Settings`, click on `SAML 2.0 Identity Provider Metadata`. Now copy and paste
the shown public certificate.

<br />

Do a `docker-compose restart` on Bookstack. You should now be able to authenticate via your Keycloak Instance.

For further Documentation refer to the [Official Docs](https://www.bookstackapp.com/docs/admin/saml2-auth/).