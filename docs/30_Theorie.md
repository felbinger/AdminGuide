# Theorie (Namen werden noch überarbeitet)

## Anwendungsbereiche für Teilempfehlungenen

### IPv6 Adresse für jeden Service einzeln
- layer 3 Protokoll "Security" für jeden Service

### Wofür benötigt man einen IPv4 -> IPv6 Proxy?
- Virtualisierungsumgebung und wenig IPv4 Adressen
- IPv6 Only Server


### IPv4-to-IPv6 Proxy

Dieser einfache IPv4-to-IPv6 Proxy unterstützt in seiner ersten Version lediglich HTTP Verbindungen auf Port 80 und TLS
Verbindungen auf Port 443. Eine Anpassung dieser Konfiguration um einige anderen Protokolle (SMTPs, IMAPs, POP3s) welche
TLS verwenden zu unterstützten ist denkbar.

Aus Gründen der Vollständigkeit hier einmal die nginx Konfiguration für den Proxy für Alpine Linux. Die Einrichtung ist
denkbar einfach: nginx installieren, die untenstehende Konfiguration kopieren und den Proxy starten:

```nginx
user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;


events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log  main;

    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80 default_server;
        location / {
            return 301 https://$host$request_uri;
        }
    }
}

stream {
    # https://gist.github.com/kekru/c09dbab5e78bf76402966b13fa72b9d2#non-terminating-tls-pass-through
    server {
        listen 443;

        proxy_connect_timeout 1s;
        proxy_timeout 3s;

        resolver 1.1.1.1 1.0.0.1 [2606:4700:4700::1111] [2606:4700:4700::1001] ipv6=on ipv4=off;

        proxy_pass $ssl_preread_server_name:443;
        ssl_preread on;
    }
}
```

### Vergleich der Proxy Möglichkeiten

![Schaubild](../img/schaubild_cloudflare-vs-transparent-proxy.png){: loading=lazy }

Aus meiner Sicht ergibt die Verwendung eines eigenen vorgeschaltenen Proxies nur Sinn, wenn mehr als ein 
Server administriert wird und die Web-Server über IPv6 Adressen exposiert bereitstellt werden.

Wird lediglich ein System betreut (wie z.B. der oben erwähnte Cloudserver), kann die zugewiesene IPv4 
Adresse natürlich ebenfalls auf den Ports 80 und 443 verwendet werden und dann auf den Reverse Proxy 
zeigen. Dadurch entfällt die Abhängigkeit zu anderen Systemen.

Sofern der Cloudserver über keine eigene IPv4 Adresse oder keine
eigenen IPv6 Adressen verfügt, sollte ein Proxy vorgeschaltet werden,
um den Nutzern, die keine IPv4/IPv6 Adresse verfügen den Zugriff zu
ermöglichen.

Wird Cloudflare Proxy verwendet erkauft man sich neben der Erreichbarkeit
diverse Vorteile (DDoS Protection,
[Web Application Firewall](https://developers.cloudflare.com/waf/managed-rules/),
[Page Rules](https://www.cloudflare.com/features-page-rules/)).

Jedoch sollte man einige Details beachten, bevor man sich auf Cloudflare festlegt.
Der Datenverkehr der Nutzer liegt bei Cloudflare unverschlüsselt vor, da diese die
TLS Pakete terminieren. In der kostenfreien Version von Cloudflare Proxy können
des Weiteren keine gestackten Subdomains (`sub.sub.domain.de`) eingerichtet werden,
da dafür kein TLS Zertifikat angefordert werden kann.



## Vergleich nginx / traefik