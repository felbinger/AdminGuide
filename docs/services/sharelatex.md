# ShareLaTeX

Eine selbst gehostete Version von [Overleaf](https://overleaf.com)

```yaml
services:
  sharelatex:
    # use latest tag for setup, use your own image (tag: with-texlive-full) after installation
    image: sharelatex/sharelatex
    restart: always
    env_file: .sharelatex.env
    environment:
      - "SHARELATEX_APP_NAME=ShareLaTeX"
      - "SHARELATEX_REDIS_HOST=redis"
      - "REDIS_HOST=redis"
      - "SHARELATEX_MONGO_URL=mongodb://mongo/sharelatex"
      #- "SHARELATEX_EMAIL_SMTP_HOST=smtp.mydomain.com"
      #- "SHARELATEX_EMAIL_SMTP_PORT=587"
      #- "SHARELATEX_EMAIL_SMTP_SECURE=false"
      #- "SHARELATEX_EMAIL_SMTP_TLS_REJECT_UNAUTH=true"
      #- "SHARELATEX_EMAIL_SMTP_IGNORE_TLS=false"
      - "ENABLED_LINKED_FILE_TYPES=url,project_file"
      - "ENABLE_CONVERSIONS=true"
      - "EMAIL_CONFIRMATION_DISABLED=true"
      - "TEXMFVAR=/var/lib/sharelatex/tmp/texmf-var"
      - "SHARELATEX_SITE_URL=https://overleaf.domain.de"
      - "SHARELATEX_NAV_TITLE=ShareLaTeX"
      - "SHARELATEX_LEFT_FOOTER=[]"
      - "SHARELATEX_RIGHT_FOOTER=[]"
      #- "SHARELATEX_HEADER_IMAGE_URL=https://somewhere.com/mylogo.png"
      #- "SHARELATEX_EMAIL_FROM_ADDRESS=team@sharelatex.com"
      #- "SHARELATEX_CUSTOM_EMAIL_FOOTER=This system is run by department x"
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/sharelatex/data:/var/lib/sharelatex"

  mongo:
    image: mongo
    restart: always
    volumes:
      - "/srv/sharelatex/mongo:/data/db"
    healthcheck:
      test: echo 'db.stats().ok' | mongo localhost:27017/test --quiet
      interval: 10s
      timeout: 10s
      retries: 5

  # muss auf Version 5 sein, sonst wird sharelatex nicht funktionieren
  redis:
    image: redis:5
    restart: always
    volumes:
      - "/srv/sharelatex/redis:/data"
```

```shell
# .sharelatex.env
#SHARELATEX_EMAIL_SMTP_USER=
#SHARELATEX_EMAIL_SMTP_PASS=
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/sharelatex.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name sharelatex.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/sharelatex.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/sharelatex.domain.de_ecc/sharelatex.domain.de.key;
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
          - "traefik.http.services.srv_sharelatex.loadbalancer.server.port=80"
          - "traefik.http.routers.r_sharelatex.rule=Host(`sharelatex.domain.de`)"
          - "traefik.http.routers.r_sharelatex.entrypoints=websecure"
    ```

### Installation von texlive-full
!!! warning ""
    Wenn du den Container mit docker-compose startest, wird das Image mit allen environment Variablen und Labels gestartet.

1. Install `texlive-full`

    !!! warning ""
        Das Ausführen des Commands wird einige Stunden dauern (variierend auf der Internetleitung des Server 2 - 4h),
        empfehle ich es in einem screen auszuführen

    !!! warning ""
        Das Image wird nach der Installation aller Packages um die 8 Gigabyte groß sein.

    ```sh
    screen -AmdS latex-installation "docker-compose exec sharelatex tlmgr update --self; tlmgr install scheme-full"
    ```

2. Speicher das aktuelle Dateisystem des Containers in einem Image mit dem Tag: `with-texlive-full`

    ```shell
    docker commit -m "installing all latex packages" $(docker-compose ps -q sharelatex) sharelatex/sharelatex:with-texlive-full
    ```

3. Ersetze den Image Tag in deiner `docker-compose.yml` von `latest` zu `with-texlive-full`

### Einen Benutzer erstellen

Um einen Admin User zu erstellen, gibt es folgenden Befehl:

```shell
docker-compose exec sharelatex /bin/bash -c "cd /var/www/sharelatex; grunt user:create-admin --email=my@email.address"
```

Ersetze `my@email.address` mit deiner E-Mail-Adresse. Du wirst jetzt einen Passwort-Reset Link bekommen, mit welchem du
das admin Passwort setzen kannst.

### Einen Benutzer löschen

Benutzer können mit folgendem Befehl gelöscht werden, aber die Projekte des Benutzers werden auch gelöscht somit sei
etwas vorsichtig mit dem Befehl.

```shell
docker-compose exec sharelatex /bin/bash -c "cd /var/www/sharelatex; grunt user:delete --email=my@email.address"
```

Ersetze die `my@email.address` mit der E-Mail-Adresse von dem Benutzer, welcher gelöscht werden soll.