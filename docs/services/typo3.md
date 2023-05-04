# TYPO3

TYPO3 ist ein Open-Source-Content-Management-System, das es Benutzern ermöglicht, leistungsstarke, skalierbare und
mehrsprachige Websites und Anwendungen zu erstellen und diese zu verwalten.

### Dockerfile
Das aktuelle [dockerhub](https://hub.docker.com/r/martinhelmich/typo3/) repo hat mehrere Versionen für den manuellen
Setup.
Für Development Gründen existiert eine 10.4 [Dockerfile](https://github.com/Ziehnert/Typo3-docker) mit einem
automatischen Setup, welches SQLite verwendet.

```yaml
  typo3:
    build: martinhelmich/typo3:$VERSION
    restart: always
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/typo3/conf:/var/www/html/typo3conf/"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/typo3.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name typo3.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/typo3.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/typo3.domain.de_ecc/typo3.domain.de.key;
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
          - "traefik.http.services.srv_typo3.loadbalancer.server.port=80"
          - "traefik.http.routers.r_typo3.rule=Host(`typo3.domain.de`)"
          - "traefik.http.routers.r_typo3.entrypoints=websecure"
    ```

Nachdem Sie den Container gestartet haben, müssen Sie die Datei `/srv/typo3/conf/AdditionalConfiguration.php`
anpassen, um das Typo3 Backend hinter dem Reverse Proxy erreichen zu können.

```php
# /srv/typo3/conf/AdditionalConfiguration.php
<?php
// '*' tells TYPO3 to use the value of reverseProxyIP for comparison
$GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxySSL'] = '*';
// reverseProxyIP equals the IP address of your reverse proxy (e.g. traefik or localhost for nginx)
$GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxyIP'] = 'localhost';
// trustedHostsPattern contains your domain OR a pattern for your requirements
$GLOBALS['TYPO3_CONF_VARS']['SYS']['trustedHostsPattern'] = 'typo3.domain.de';
// use ip address from HTTP_X_FORWARDED_FOR for remote address and
// use host name from HTTP_X_FORWARDED_HOST
$GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxyHeaderMultiValue'] = 'first';
?>
```
