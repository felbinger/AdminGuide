# Keycloak

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    volumes:
      - "/srv/keycloak/postgres:/var/lib/postgresql/data"

  keycloak:
    image: ghcr.io/secshellnet/keycloak
    restart: always
    command: start
    env_file: .keycloak.env
    ports:
      - "[::1]:8000:8080"
    volumes:
    #  - "/srv/keycloak/extensions:/opt/jboss/keycloak/standalone/deployments"
      - "/etc/localtime:/etc/localtime:ro"
```

```shell
# .postgres.env
POSTGRES_HOST_AUTH_METHOD=trust
POSTGRES_USER=keycloak
POSTGRES_DB=keycloak
```

```shell
# .keycloak.env
KC_DB_URL_HOST=postgres
KC_DB_USERNAME=keycloak
KC_DB_PASSWORD=none
KC_DB_URL_DATABASE=keycloak
KC_PROXY=edge
KC_HOSTNAME_STRICT=false
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=S3cr3T
```

For this service we need some nginx adjustments. First, we have two vhosts:
One for administrative purpose and one for the users to authenticate to a service.  
In the example configuration below the admin vhost is not exposed to the internet, 
which is the reason why this service is listening only on ipv4 addresses.
```nginx
server {
    server_name keycloak.pve2.secshell.net;
    listen 0.0.0.0:443 ssl http2;

    ssl_certificate /root/.acme.sh/keycloak.pve2.secshell.net_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/keycloak.pve2.secshell.net_ecc/keycloak.pve2.secshell.net.key;
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
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
    }

    # redirect to admin console
    location ~* ^(\/)$ {
        return 301 https://keycloak.pve2.secshell.net/admin/master/console/;
    }
}
```

```
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name id.secshell.net;
    listen [2001:db8::fdfd:dead:beef:affe]:443 ssl http2;

    ssl_certificate /etc/ssl/id.secshell.net.crt;
    ssl_certificate_key /etc/ssl/id.secshell.net.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    # modern configuration
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    # only allow cloudflare to connect to your nginx
    ssl_client_certificate /etc/ssl/cloudflare_ca.crt;
    ssl_verify_client on;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
            proxy_pass http://[::1]:8000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
    }

    # redirect to account login
    location ~* ^(\/)$ {
        return 301 https://id.secshell.net/realms/main/account/;
    }

    # do not allow keycloak admin from this domain
    location ~* (\/admin\/|\/realms\/master\/) {
        return 403;
    }
}
```