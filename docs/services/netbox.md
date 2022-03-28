# NetBox

!!! warning ""
	Rewrite required!

First clone the netbox release, then overwrite some settings:
```shell
git clone -b release https://github.com/netbox-community/netbox-docker.git /home/admin/netbox

cat <<_EOF > /home/admin/netbox/docker-compose.override.yml
version: '3.4'

services:
  netbox:
    ports:
      - "[::1]:8083:8080"
_EOF

cat <<_EOF > /home/admin/netbox/env/postgres.env
POSTGRES_DB=netbox
POSTGRES_HOST_AUTH_METHOD=trust
POSTGRES_USER=netbox
_EOF

cat <<_EOF > /home/admin/netbox/env/redis.env
REDIS_PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | fold -w32 | head -n1)
_EOF

source /home/admin/netbox/env/redis.env

cat <<_EOF > /home/admin/netbox/env/netbox.env
DB_PASSWORD=irrelevant
REDIS_PASSWORD=${REDIS_PASSWORD}
LOGIN_REQUIRED=true
TIME_ZONE=Europe/Berlin
SECRET_KEY=$(cat /dev/urandom | tr -dc A-Za-z0-9 | fold -w32 | head -n1)
SUPERUSER_PASSWORD=AdminGuide!
_EOF
```

Afterwards you can login using the credentials `admin` / `AdminGuide!`.


## E-Mail

`/home/admin/netbox/env/netbox.env`:
```env
EMAIL_FROM=noreply@domain.de
EMAIL_PASSWORD=S3cr3T
EMAIL_PORT=587
EMAIL_SERVER=mail.domain.de
EMAIL_SSL_CERTFILE=
EMAIL_SSL_KEYFILE=
EMAIL_TIMEOUT=5
EMAIL_USERNAME=noreply@domain.de
# EMAIL_USE_SSL and EMAIL_USE_TLS are mutually exclusive, i.e. they can't both be `true`!
EMAIL_USE_SSL=true
EMAIL_USE_TLS=false
```

## OpenID Connect / Keycloak

Set `User Info Signed Response Algorithm` and `Request Object Signature Algorithm` in the keycloak client (in the category: Fine Grain OpenID Connect Configuration ) to RS256.

Create a mapper in the created keycloak client:
| Setting                  | Value                         |
|--------------------------|-------------------------------|
| Name                     | aud                           |
| Mapper Type              | Audience                      |
| Included Custom Audience | <name of the keycloak client> |
| Add to ID token          | OFF                           |
| Add to access token      | ON                            |

Extend `/home/admin/netbox/env/netbox.env`:
```env
REMOTE_AUTH_BACKEND='social_core.backends.keycloak.KeycloakOAuth2'
```

Also extend the `/home/admin/netbox/configuration/configuration.py`:
```py
## OIDC Keycloak Configuration
SOCIAL_AUTH_KEYCLOAK_ID_KEY = 'preferred_username'
SOCIAL_AUTH_KEYCLOAK_KEY = '<client id>'
SOCIAL_AUTH_KEYCLOAK_SECRET = '<client secret>'
SOCIAL_AUTH_KEYCLOAK_PUBLIC_KEY = \
  '<public key>'
SOCIAL_AUTH_KEYCLOAK_AUTHORIZATION_URL = \
  'https://id.domain.de/realms/main/protocol/openid-connect/auth'
SOCIAL_AUTH_KEYCLOAK_ACCESS_TOKEN_URL = \
  'https://id.domain.de/realms/main/protocol/openid-connect/token'
```

The public key can be aquired in the keycloak realm settings:
![Keycloak Realm Settings -> Keys -> Public Key of RS256 Key](../img/services/netbox_keycloak_realm_keys.png){: loading=lazy }