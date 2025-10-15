# nginx

## Installation

Zunächst wird nginx auf dem System installiert
```shell
sudo apt install -y nginx-full
```

Für den Betrieb eines Webservers sind TLS Zertifikate erforderlich. Jene, die im Browser als
vertrauenswürdig erkannt werden können beispielsweise über Anbieter wie ZeroSSL oder Let's Encrypt
bezogen werden. In unserem Fall beziehen wir diese von Let's Encrypt mithilfe von [acme.sh](https://github.com/acmesh-official/acme.sh).

!!! note
    Der folgende Block sollte direkt unter dem root-Nutzer ausgeführt werden,
    da die Installation Standardmäßig im Nutzerverzeichnis ausgeführt wird.

    Mithilfe des Befehls `sudo -s` kann in den root-Nutzerkontext gewechselt werden.

```shell
# acme.sh installieren und default ca auf Let's Encrypt setzen
curl https://get.acme.sh | sh -s email=acme@domain.de
ln -s /root/.acme.sh/acme.sh /usr/bin/acme.sh
acme.sh --install-cronjob

acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
```

### IPv6 Adresse pro Virtual-Host
Sofern geplant ist, jedem Virtual Host eine eigene IPv6 Adresse zu geben (siehe Theoretische
Grundlagen) empfielt sich den nginx systemd-Service um einige Sekunden zu verzögern, sodass
sichergestellt werden kann, dass das System die IPv6 Adressen der Netzwerkschnittstelle bereits
hinzugefügt hat.

![Result of `systemctl status nginx`](../img/nginx/nginx-failed-ipv6-not-assignable.png){: loading=lazy }

Dazu muss in der Datei `/lib/systemd/system/nginx.service` vor der ersten `ExecStartPre` Zeile folgendes hinzugefügt werden:
```shell
# make sure the additional ipv6 addresses (which have been added with post-up)
# are already on the interface (only required for enabled nginx service on system boot)
ExecStartPre=/bin/sleep 5
```

## Konfiguration für neue Dienste

Folgende Schritte sind notwendig, um ein neues HTTP Routing zu konfigurieren:

1. Dienst aufsetzen.
2. Port-Binding von Dienst auf IPv6 localhost (`::1`) des Hosts.
3. TLS Zertifkat über acme.sh anfordern.
4. Optional: Eigene IPv6 Adresse für Virtual Host konfigurieren.
5. nginx Virtual-Host konfigurieren und aktivieren.
6. Konfiguration testen und nginx neu laden.

### Dienst aufsetzen
...

### Port-Binding von Dienst auf IPv6 Localhost (`::1`) des Hosts
Die Containerdefinition muss einen entsprechenden Eintrag erhalten, sodass der Port
auf dem der Container den Dienst bereitstellt, auf dem Hostsystem lokal verfügbar ist.
Dabei darf natürlich nur die linke Seite (hier 8081) verändert werden.
```yaml
    ports:
      - "[::1]:8081:80"
```

### TLS Zertifkat über acme.sh anfordern

Für acme.sh müssen die erforderlichen Umgebungsvariablen für die gewünschte
[ACME Challenge](https://letsencrypt.org/docs/challenge-types/) gesetzt
sein. Für die DNS API's der Anbieter empfielt sich ein Blick in
[diese Tabelle](https://github.com/acmesh-official/acme.sh/wiki/dnsapi).

```shell
# Beispielkonfiguration für Cloudflare DNS API
export CF_Token=
acme.sh --issue --keylength ec-384 --dns dns_cf -d service.domain.de
```

### Optional: Eigene IPv6 Adresse für Virtual Host konfigurieren
Sofern eine eigene IPv6 Adresse für diesen Dienst verwendet werden soll,
wird diese der entsprechenden Netzwerkschnittstelle hinzugefügt, sodass
diese in nginx verwendet werden kann.

=== "Debian"
    ```shell
    # /etc/network/interfaces

    # ...

    iface eth0 inet6 static
        # ipv6 address of the host
        address 2001:db8:1234:5678::1/64
        gateway 2001:db8::1

        # service.domain.de
        post-up ip -6 a add 2001:db8:1234:5678:5eca:dc9d:fd4e:6564/64 dev $IFACE
        pre-down ip -6 a del 2001:db8:1234:5678:5eca:dc9d:fd4e:6564/64 dev $IFACE
    ```

=== "Ubuntu"
    Da Ubuntu `netplan` zum Konfigurieren der Netzwerkeschnittstellen verwendet, muss die entsprechende Konfiguration im
    Verzeichnis `/etc/netplan` angepasst werden.
    Die Konfigurationsdatei sollte ungefähr wie folgt aussehen:
    ```yaml
    network:
        version: 2
        renderer: networkd
        ethernets:
            enp1s0:
                addresses:
                    - 10.10.10.2/24
                    - 2001:db8::5/64
                dhcp4: no
                routes:
                    - to: 0.0.0.0/0
                    via: 10.10.10.1
                    - to: ::/0
                    via: 2001:db8::1
                nameservers:
                    addresses: [10.10.10.1, 1.1.1.1, 2001:470:20::2]
    ```
    Wenn die Konfigurationsdatei gefunden wurde, fügt man in dem `addresses` Abschnitt die neue IPv6 Adresse wie
    folgt hinzu:
    ```yaml
    addresses:
        ...
        - 2001:db8:4a:90a:d8d5:dbf4:fd80:8f80
    ```

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

### Konfiguration aktivieren, testen und anwenden.
Nun muss noch der Link zu `/etc/nginx/sites-enabled/` angelegt werden,
bevor die Konfiguration von nginx getestet werden kann und anschließend
nginx neu geladen werden kann, sofern der Test keine Fehler ergeben hat:

```shell
ln -s /etc/nginx/sites-available/service.domain.de \
    /etc/nginx/sites-enabled/

nginx -t && systemctl reload nginx
```
