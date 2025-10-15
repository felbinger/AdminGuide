# nginx

Egal ob nginx auf beiden Addressfamilien (IPv4 und IPv6) oder lediglich auf IPv6 exposiert
werden soll, sind die folgenden Schritte notwendig.

{% include-markdown "../../includes/installation/nginx_base.md" %}

### nginx Virtual-Host konfigurieren und aktivieren
Anschließend wird die Virtual Host Konfiguration unter dem Pfad
`/etc/nginx/sites-available/domain` angelegt.

!!! note
    Standardmäßig wird der nginx auf beiden Adressfamilien exposiert.

    Ist lediglich IPv6 (z. B. für die Verwendung eines Proxy Servers) erwünscht,
    müssen die `listen` Direktiven im Serverblock wie folgt angepasst werden:

    ```nginx
    listen [::]:80;
    ```

    Ist weitergehend die Verwendung einer eigenen IPv6 Adresse pro Service erwünscht,
    sollte diese anstelle von :: eingefügt werden:

    ```nginx
    listen [2001:db8::dead]:80;
    ```

```nginx
# https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
server {
    server_name service.domain.de;               # <---
    listen 0.0.0.0:80;
    listen [::]:80;
    http2 on;

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    server_name service.domain.de;               # <---
    listen 0.0.0.0:443 ssl;
    listen [::]:443 ssl;

    ssl_certificate /root/.acme.sh/service.domain.de_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/service.domain.de_ecc/service.domain.de.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    # modern configuration
    ssl_protocols TLSv1.3;
    ssl_ecdh_curve X25519:prime256v1:secp384r1;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    location / {
        proxy_pass http://[::1]:8000/;           # <---
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

{% include-markdown "../../includes/installation/nginx_enable_test_apply_vhost.md" %}
