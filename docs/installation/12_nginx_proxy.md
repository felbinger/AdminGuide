# nginx mit eigenem Proxy

Wenn nginx mit einem eigenen transparenten Proxy für IPv4 Anfragen eingesetzt werden soll, 
benötigt man TLS Zertifikate, die im Browser validiert werden können.

{% include-markdown "../../includes/installation/nginx_base.md" %}

### nginx Virtual-Host konfigurieren und aktivieren
Anschließend wird die Virtual Host Konfiguration unter dem Pfad
`/etc/nginx/sites-available/domain` angelegt. Dabei müssen hauptsächlich die 
mit Pfeil markierten Zeilen beachtet werden.
```nginx
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name service.domain.de;               # <---
    listen [::]:80 http2;                        # <---

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    server_name service.domain.de;               # <---
    listen [::]:443 ssl http2;                   # <---

    ssl_certificate /root/.acme.sh/service.domain.de_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/service.domain.de_ecc/service.domain.de.key;
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
        proxy_pass http://[::1]:8081/;           # <---
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
