# nginx mit eigenem Proxy

Wenn nginx mit einem eigenen transparenten Proxy für IPv4 Anfragen eingesetzt werden soll, 
benötigt man TLS Zertifikate, die im Browser validiert werden können. Kostenlose TLS Zertifikate 
können über Anbieter wie ZeroSSL oder Let's Encrypt bezogen werden. In unserem Fall beziehen wir 
diese von Let's Encrypt mithilfe von [acme.sh](https://github.com/acmesh-official/acme.sh).

```shell
# mit root-Rechten ausführen
apt install nginx-full

# acme.sh installieren und default ca auf Let's Encrypt setzen
curl https://get.acme.sh | sh -s email=acme@domain.de
ln -s /root/.acme.sh/acme.sh /usr/bin/acme.sh
acme.sh --install-cronjob

acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
```

## IPv6 Adresse pro Virtual-Host
Sofern geplant ist, jedem Virtual Host eine eigene IPv6 Adresse zu geben empfielt sich
den nginx systemd-Service um einige Sekunden zu verzögern, sodass sichergestellt werden 
kann, dass das System die IPv6 Adressen der Netzwerkschnittstelle bereits hinzugefügt hat.
Dieses Verfahren wurde auch [hier](https://docs.ispsystem.com/ispmanager-business/troubleshooting-guide/if-nginx-does-not-start-after-rebooting-the-server) beschrieben.

![Result of `systemctl status nginx`](../img/nginx/nginx-failed-ipv6-not-assignable.png){: loading=lazy }

Dazu muss in der Datei `/lib/systemd/system/nginx.service` vor der ersten `ExecStartPre` Zeile folgendes hinzugefügt werden:
```shell
# make sure the additional ipv6 addresses (which have been added with post-up) 
# are already on the interface (only required for enabled nginx service on system boot)
ExecStartPre=/bin/sleep 5
```

### Konfiguration für neue Dienste

Folgende Schritte sind notwendig, um ein neues HTTP Routing zu konfigurieren:
1. Dienst aufsetzen.
2. Port-Binding von Dienst auf IPv6 Localhost (`::1`) des Hosts.
3. TLS Zertifkat über acme.sh anfordern.
4. Optional: Eigene IPv6 Adresse für Virtual Host konfigurieren.
5. nginx Virtual-Host konfigurieren und aktivieren.
6. Konfiguration testen und nginx neu laden.

#### Dienst aufsetzen
...

#### Port-Binding von Dienst auf IPv6 Localhost (`::1`) des Hosts
Die Containerdefinition muss ein entsprechenden Eintrag erhalten, sodass der Port 
auf dem der Container den Dienst bereitstellt auf dem Hostsystem lokal verfügbar ist.
Dabei darf natürlich nur die linke Seite (hier 8081) verändert werden.
```yaml
    ports:
      - "[::1]:8081:80"
```

#### TLS Zertifkat über acme.sh anfordern

Für acme.sh müssen die erforderlichen Umgebungsvariablen für die gewünschte 
[ACME Challenge](https://letsencrypt.org/docs/challenge-types/) gesetzt 
sein. Für die DNS API's der Anbieter empfielt sich ein Blick in 
[diese Tabelle](https://github.com/acmesh-official/acme.sh/wiki/dnsapi).

```shell
# Beispielkonfiguration für Cloudflare DNS API
export CF_Account_ID=
export CF_Zone_ID=
export CF_Token=
acme.sh --issue --keylength ec-384 --dns dns_cf -d service.domain.de
```

{% include-markdown "../../includes/additional_ipv6.md" %}

#### nginx Virtual-Host konfigurieren und aktivieren
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
        proxy_set_header X-Forwarded-SSL on;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

{% include-markdown "../../includes/nginx_enable_test_apply_vhost.md" %}
