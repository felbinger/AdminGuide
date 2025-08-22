# Theorie (Namen werden noch überarbeitet)

## Anwendungsbereiche für Teilempfehlungenen

### IPv6 Adresse für jeden Service einzeln
Wenn man jeden Server mit einer separaten Adresse (in unserem Fall IPv6, da wir kein IPv4 Netz besitzen) versorgt, so kann man direkt auf OSI Layer 3 Schicht nachvollziehen auf welchem Service die Request kam. Falls diese Request eine bösartige ist, kann man sehr gut einen Service gezielt ausschalten bzw. schnell die IP Adresse für diesen Service ändern.
Wenn man für alle Services eine IP Adresse verwenden würde, so könnte man frühestens auf Layer 5 (TLS/SNI) nachvollziehen auf welcher Applikation die Request kam. Alternativ auch auf Layer 7, aber dies sollte nicht der Anspruch sein und wäre auch zu viel Aufwand alle Application Logs nach einer IP Adresse zu durchsuchen.



### Wofür benötigt man einen IPv4 -> IPv6 Proxy?
#### Use Case 1 - Virtualisierung mit nur einer IPv4 Adresse
Wenn man sich jetzt vorstellt, dass wir einen Server haben, auf dem zwei virtuelle Maschinen laufen auf welche jeweils ein Webserver laufen soll, muss man sich fragen wie man damit umgeht.
1. Wir können uns für einen der Webserver entscheiden
2. Aufsetzen eines zentralen reverse Proxies
3. IPv4 -> IPv6 Proxy

=== "Für einen Webserver entscheiden"
    - Keine Option, da man beide Webserver verwenden will

=== "Aufsetzen eines zentralen reverse Proxies"
    - Pro:
        - Beide VMs können exposed werden
        - zentralisierter Aufruf auf einen reverse Proxy
    - Cons:
        - langsamere Laufzeit durch mehre Proxys (Die Proxys auf den VMs brauchen wir ja immer noch)
        - SPOF (Single point of failure) - Wenn der erste reverse Proxy nicht mehr funktioniert, kann auf kein Service mehr zugegriffen werden
        - Vermehrter Debugging Aufwand durch mehrere Verbindungsstellen
        - Aufwendigere Konfiguration (spezifische Header Einstellungen (Real-IP Forwarded-For))

=== "IPv4 -> IPv6 Proxy"
    - Pro:
        - Für IPv6 geringere Laufzeit (veraltetes IPv4 Protokoll)
        - Reverse Proxies der VMs sind direkt im Internet
            - dadurch keine Header Konfiguration nötig
        - Falls der zentrale IPv4 Proxy ist der Service immer noch erreichbar
    - Contra
        - Uns keine bekannt, falls euch welche einfallen, bitten wir um einen Pull Request


#### Use Case 2 - IPv6 only Server
Man stelle sich vor, dass man ganz viele Server hat. Um Kosten zu sparen gibt man jedem Server nur ein IPv6 Netz und keine IPv4 Adresse. So braucht man nur einen zentralen IPv4->IPv6 Proxy um die Erreichbarkeit der Server über IPv4 sicher zu stellen.



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