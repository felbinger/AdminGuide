---
tags:
  - Communication
hide:
  - tags
---
# Jitsi

Der [Self-Hosting Guide](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker) von Jitsi ist eigentlich selbsterklärend.

```shell
mkdir -p /home/admin/jitsi/
cd /home/admin/jitsi/

wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/docker-compose.yml -O /home/admin/jitsi/docker-compose.yml
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/env.example -O /home/admin/jitsi/.env

# Konfigurationsordner ändern
sed -i 's|CONFIG=.*|CONFIG=/srv/jitsi|g' .env

# Neue secrets generieren
curl https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/gen-passwords.sh | bash
```

Passen Sie die `.env` Datei nach Ihren Wünschen an und richten die Port-Weiterleitungen / Traefik Labels für den jitsi/web Container ein:

=== "nginx"
    ```yaml
        ports:
            - '[::1]:8000:80'
    ```

    ```nginx
    # /etc/nginx/sites-available/jitsi.example.com
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
    server {
        server_name jitsi.example.com;
        listen 0.0.0.0:443 ssl;
        listen [::]:443 ssl;
        http2 on;

        ssl_certificate /root/.acme.sh/jitsi.example.com_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/jitsi.example.com_ecc/jitsi.example.com.key;
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
          - "traefik.http.services.srv_jitsi.loadbalancer.server.port=80"
          - "traefik.http.routers.r_jitsi.rule=Host(`jitsi.example.com`)"
          - "traefik.http.routers.r_jitsi.entrypoints=websecure"
    ```

## Jitsi Konfiguration
Da bei jedem Start des Containers die Datei `/srv/jitsi/web/config.js`
von den Umgebungsvariablen (`.env`) generiert wird, sind Änderungen
an dieser Datei nicht Zielführend. Die Datei `/srv/jitsi/web/interface_config.js`
kann angepasst werden, um Beispielsweise das Wasserzeichen von Jitsi zu entfernen.

## OpenID Connect
Siehe [github.com/MarcelCoding/jitsi-openid#docker-compose](https://github.com/MarcelCoding/jitsi-openid#docker-compose)

## Erweiterungen der Jitsi Instanz
### Etherpad
Etherpad ermöglicht es Dokumente gemeinsam in Echtzeit zu bearbeiten.

Die Containerdefinition befindet sich in der Datei [etherpad.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/etherpad.yml).

Kopieren Sie diese in Ihre `docker-compose.yml` und ergänzen Sie die fehlenden Umgebungsvariablen (für die Verbinmdung mit der eigenen Datenbank):

```yaml
    etherpad:
      env_file: .etherpad.env
```

```shell
# .etherpad.env
DB_TYPE=postgres
DB_HOST=localhost
DB_PORT=5432
DB_NAME=etherpad
DB_USER=etherpad
DB_PASS=S3cR3T
```

### Jibri
Die [Jitsi Broadcasting Infrastruktur](https://github.com/jitsi/jibri) ermöglicht das Aufnehmen und Streamen in einem
Jitsi Meeting.

Die Containerdefinition befindet sich in der Datei [jibri.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/jibri.yml).
