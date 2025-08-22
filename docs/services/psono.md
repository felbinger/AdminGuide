# Psono

Psono ist ein self-hosted open source passwort manager. Er auf einfache User Erfahrung optimiert und ist sehr simpel
aufzusetzen und zu konfigurieren.


```yaml
services:
  postgres:
    restart: always
    image: postgres:13-alpine
    env_file: .postgres.env
    environment:
      POSTGRES_USER: psono
    volumes:
      - "/srv/psono/postgres:/var/lib/postgresql/data"

  psono-combo:
    image: psono/psono-combo:latest
    restart: always
    ports:
      - "[::1]:8000:80"
    command: sh -c "sleep 5 && /bin/sh /root/configs/docker/cmd.sh"
    volumes:
      - /srv/psono/data/settings.yaml:/root/.psono_server/settings.yaml
      - /srv/psono/client/config.json:/usr/share/nginx/html/portal/config.json
    sysctls:
      - net.core.somaxconn=65535
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3t
```

=== "nginx"
    ```yaml
    ports:
      - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/psono.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7

    server {
        server_name psono.domain.de;
        listen 0.0.0.0:443 ssl http2
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/passbolt.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/passbolt.domain.de_ecc/passbolt.domain.de.key;
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

        add_header Referrer-Policy same-origin;
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";

        # If you have the fileserver too, then you have to add your fileserver URL e.g. https://fs01.domain.de as connect-src too:
        add_header Content-Security-Policy "default-src 'none';  manifest-src 'self'; connect-src 'self' https://static.psono.com https://api.pwnedpasswords.com https://storage.googleapis.com https://*.digitaloceanspaces.com https://*.blob.core.windows.net https://*.s3.amazonaws.com; font-src 'self'; img-src 'self' data:; script-src 'self'; style-src 'self' 'unsafe-inline'; object-src 'self'; child-src 'self'";

        client_max_body_size 256m;

        gzip on;
        gzip_disable "msie6";

        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_buffers 16 8k;
        gzip_http_version 1.1;
        gzip_min_length 256;
        gzip_types text/plain text/css application/json application/x-javascript application/javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

        location / {
           proxy_pass http://[::1]:8000/;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_http_version 1.1;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header Host $http_host;
           proxy_set_header Connection "Upgrade";
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header X-Nginx-Proxy true;
           proxy_set_header X-Forwarded-Proto $scheme;
        }

        location ~* \.(?:ico|css|js|gif|jpe?g|png|eot|woff|woff2|ttf|svg|otf)$ {
            proxy_pass http://[::1]:8000;
            expires 30d;
            add_header Pragma public;
            add_header Cache-Control "public";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_hide_header Content-Security-Policy;
        }
    }
    ```


=== "Traefik"
    Coming Soon...



### Serverkeys erstellen
```shell
docker run --rm -ti psono/psono-combo:latest python3 ./psono/manage.py generateserverkeys
```

Die Ausgabe des Befehls temporär zwischenspeichern. Diese wird für den nächsten Schritt benötigt.


### Erstelle `settings.yaml` in `/srv/psono/data/settings.yaml`
```yaml
# Replace the keys below with the one from the generateserverkeys command.
SECRET_KEY: 'SECRET_KEY_FROM_COMMAND_ABOVE'
ACTIVATION_LINK_SECRET: 'SECRET_KEY_FROM_COMMAND_ABOVE'
DB_SECRET: 'SECRET_KEY_FROM_COMMAND_ABOVE'
EMAIL_SECRET_SALT: 'SECRET_KEY_FROM_COMMAND_ABOVE'
PRIVATE_KEY: 'SECRET_KEY_FROM_COMMAND_ABOVE'
PUBLIC_KEY: 'SECRET_KEY_FROM_COMMAND_ABOVE'

# Switch DEBUG to false if you go into production
DEBUG: False

# Adjust this according to Django Documentation https://docs.djangoproject.com/en/2.2/ref/settings/
ALLOWED_HOSTS: ['*']

# Should be your domain without "www.". Will be the last part of the username
ALLOWED_DOMAINS: ['domain.de']

# Should be the URL of the host under which the host is reachable
# If you open the url and append /info/ to it you should have a text similar to {"info":"{\"version\": \"....}
HOST_URL: 'https://psono.domain.de/server'

# The email used to send emails, e.g. for activation (Nice, but not necessary)
EMAIL_FROM: 'the-mail-for-for-example-useraccount-activations@test.com'
EMAIL_HOST: 'smtp.domain.de'
EMAIL_HOST_USER: ''
EMAIL_HOST_PASSWORD : ''
EMAIL_PORT: 25
EMAIL_SUBJECT_PREFIX: ''
EMAIL_USE_TLS: False
EMAIL_USE_SSL: False
EMAIL_SSL_CERTFILE:
EMAIL_SSL_KEYFILE:
EMAIL_TIMEOUT: 10


# Enables the management API, required for the psono-admin-client / admin portal (Default is set to False)
MANAGEMENT_ENABLED: True

# Your Postgres Database credentials
# ATTENTION: If executed in a docker container, then "localhost" will resolve to the docker container, so
# "localhost" will not work as host. Use the public IP or DNS record of the server.
DATABASES:
    default:
        'ENGINE': 'django.db.backends.postgresql_psycopg2'
        'NAME': 'psono'
        'USER': 'psono'
        'PASSWORD': 'S3cr3t'
        'HOST': 'postgres'
        'PORT': '5432'

# The path to the template folder can be "shadowed" if required later
TEMPLATES: [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': ['/root/psono/templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]
```

Für weitere Informationen und Optionen für die `settings.yaml` siehe [Offizielle Dokumentation](https://doc.psono.com/admin/installation/install-psono-ce.html#installation)

### Erstellen der Client `config.json` in `/srv/psono/config/config.json`
```json
{
  "backend_servers": [{
    "title": "PSONO",
    "url": "https://psono.domain.de/server"
  }],
  "base_url": "https://psono.domain.de/",
  "allow_custom_server": true,
  "allow_registration": true,
  "allow_lost_password": true,
  "disable_download_bar": false,
  "remember_me_default": false,
  "trust_device_default": false,
  "authentication_methods": ["AUTHKEY", "LDAP"],
  "saml_provider": []
}
```
Einzelne Attribute können gemäß persönlichen Präferenzen angepasst werden. Ansonsten kann die config nach Änderung der
Domains so ohne Probleme verwendet werden und jederzeit auch noch später angepasst werden.

### Cronjob erstellen
1. Öffne den root Crontab mit `sudo crontab -e`
2. Füge am Ende der Datei folgende Zeile ein `30 2 * * * docker exec psono-psono-combo-1 python3 ./psono/manage.py cleartoken`


### User erstellen
```shell
docker compose exec python3 ./psono/manage.py createuser \
                username@example.com \
                myPassword \
                email@something.com
```

Jetzt kann der User sich unter https://psono.domain.de/ einloggen.


### User zum Admin erklären
```shell
docker compose exec python3 ./psono/manage.py promoteuser username@example.com superuser
```

Der Admin Login (mit einem Dashboard, Userverwaltung, etc.) befindet sich unter https://psono.domain.de/portal/


Weiter Informationen: [Offizelle Dokumentation](https://doc.psono.com/admin/overview/summary.html)
