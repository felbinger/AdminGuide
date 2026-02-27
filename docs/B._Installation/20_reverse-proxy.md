# 2. Reverse Proxy

## Installation

=== "nginx"
    Zunächst wird nginx auf dem System installiert.
    ```shell
    sudo apt install -y nginx-full
    ```

    Für die Installation von acme.sh wird zunächst in den root-Kontext gewechselt.
    Dies ist notwendig, weil acme.sh in das Nutzerverzeichnis installiert wird.
    ```shell
    sudo -s
    ```
    ```shell
    # acme.sh installieren und default ca auf Let's Encrypt setzen
    curl https://get.acme.sh | sh -s email=acme@domain.de
    ln -s /root/.acme.sh/acme.sh /usr/bin/acme.sh
    acme.sh --install-cronjob

    acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
    ```

    Anschließend kann die Datei `/etc/nginx/sites-available/default` durch folgenden Codeblock ersetzt werden.
    ```nginx
    server {
        listen 0.0.0.0:80;
        listen [::]:80;
        http2 on;

        location / {
            return 301 https://$host$request_uri;
        }
    }
    ```
    Diese Server Direktive regelt, dass der Server lediglich TLS Verschlüsselte Anfragen verarbeitet.


    Sofern geplant ist, jedem Virtual Host eine eigene IPv6 Adresse zu geben empfiehlt sich den nginx
    systemd-Service um einige Sekunden zu verzögern, sodass sichergestellt werden kann, dass das System
    die IPv6 Adressen der Netzwerkschnittstelle bereits hinzugefügt hat.

    ![Result of `systemctl status nginx`](../img/nginx/nginx-failed-ipv6-not-assignable.png){: loading=lazy }

    Dazu muss in der Datei `/lib/systemd/system/nginx.service` vor der ersten `ExecStartPre` Zeile folgendes hinzugefügt werden:
    ```shell
    # Make sure the additional ipv6 addresses (which have been added with post-up)
    # are already on the interface (only required for enabled nginx service on system boot)
    ExecStartPre=/bin/sleep 5
    ```

=== "Traefik"
    Zunächst wird die Containerdefinition im Verzeichnis `/home/admin/traefik/docker-compose.yml` angelegt:

    ```yaml
    services:
    traefik:
        image: traefik:v2.9
        restart: always
        command:
        - "--api.insecure=true"
        - "--metrics.prometheus=true"
        #- "--log.level=DEBUG"
        - "--accesslog=true"

        - "--providers.docker=true"
        - "--providers.docker.exposedbydefault=false"
        - "--providers.docker.network=proxy"

        - "--providers.file.directory=/configs/"

        - "--entrypoints.web.address=:80"
        - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
        - "--entrypoints.web.http.redirections.entrypoint.scheme=https"

        - "--entrypoints.websecure.address=:443"
        #- "--entrypoints.websecure.http.middlewares=mw_hsts@file,mw_compress@file"
        - "--entryPoints.websecure.http.tls=true"
        - "--entryPoints.websecure.http.tls.certresolver=myresolver"
        - "--entryPoints.websecure.http.tls.domains[0].main=domain.de"
        - "--entryPoints.websecure.http.tls.domains[0].sans=*.domain.de"

        - "--certificatesresolvers.myresolver.acme.dnschallenge=true"
        - "--certificatesresolvers.myresolver.acme.dnschallenge.provider=cloudflare"
        - "--certificatesresolvers.myresolver.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
        - "--certificatesresolvers.myresolver.acme.dnschallenge.delayBeforeCheck=10"
        - "--certificatesresolvers.myresolver.acme.email=admin@domain.de"
        - "--certificatesresolvers.myresolver.acme.storage=/acme/acme.json"
        #- "--certificatesresolvers.myresolver.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
        labels:
        - "traefik.enable=true"
        - "traefik.http.services.srv_traefik.loadbalancer.server.port=8080"
        - "traefik.http.routers.r_traefik.rule=Host(`traefik.domain.de`)"
        - "traefik.http.routers.r_traefik.entrypoints=websecure"
        env_file: .traefik.env
        ports:
        - "80:80"
        - "443:443"
        volumes:
        - "/srv/traefik/acme:/acme"
        - "/srv/traefik/dynamic.yml:/configs/dynamic.yml"
        - "/srv/traefik/middlewares.yml:/configs/middlewares.yml"
        - "/etc/localtime:/etc/localtime:ro"
        - "/var/run/docker.sock:/var/run/docker.sock:ro"
        networks:
        - "proxy"

    static:
        image: nginx:stable-alpine
        restart: always
        labels:
        # BASIC CONFIGURATION
        - "traefik.enable=true"
        - "traefik.http.services.srv_static.loadbalancer.server.port=80"

        # ERROR PAGES
        # you can use my error_pages: https://github.com/felbinger/AdminGuide/tree/master/error_pages
        - "traefik.http.middlewares.error40x.errors.status=403-404"
        - "traefik.http.middlewares.error40x.errors.service=srv_static"
        - "traefik.http.middlewares.error40x.errors.query=/error/{status}.html"
        - "traefik.http.middlewares.error30x.errors.status=300-308"
        - "traefik.http.middlewares.error30x.errors.service=srv_static"
        - "traefik.http.middlewares.error30x.errors.query=/error/30x.html"

        # DOMAIN ROOT CONTENT
        - "traefik.http.routers.r_static_root.rule=HostRegexp(`domain.de`, `{subdomain:[a-z0-9]+}.domain.de`)"
        - "traefik.http.routers.r_static_root.entrypoints=websecure"
        - "traefik.http.routers.r_static_root.priority=10"
        - "traefik.http.middlewares.mw_static_root.addprefix.prefix=/domain_root/"
        - "traefik.http.routers.r_static_root.middlewares=mw_static_root@docker,error40x@docker,error30x@docker"
        volumes:
        - "/srv/static/webroot:/usr/share/nginx/html/"
        networks:
        - "proxy"

    networks:
    proxy:
        external: true
    ```

    Wird Traefik hinter einem IPv4-to-IPv6 Proxy eingesetzt sollte dieser lediglich auf IPv6 exposed werden.

    ```yaml
    services:
      traefik:
        # ...
        ports:
          - "[::]:80:80"
          - "[::]:443:443"
    ```

    Nun müssen noch einige Konfigurationen angelegt werden:
    ```yaml
    # /srv/traefik/middlewares.yml
    http:
    middlewares:
        mw_compress:
        compress: true
        mw_hsts:
        headers:
            contentTypeNosniff: true
            browserXssFilter: true
            forceSTSHeader: true
            sslRedirect: true
            stsPreload: true
            stsSeconds: 315360000
            stsIncludeSubdomains: true
            customResponseHeaders:
            X-Forwarded-Proto: https
            X-Frame-Options: sameorigin
    ```

    ```yaml
    # /srv/traefik/dynamic.yml
    tls:
    options:
        default:
        minVersion: VersionTLS13
        sniStrict: true
        cipherSuites:
            # TLS 1.3
            - TLS_AES_256_GCM_SHA384
            - TLS_CHACHA20_POLY1305_SHA256
            - TLS_AES_128_GCM_SHA256
    ```

    Anschließend wird das `proxy` Docker Netzwerk angelegt und Traefik gestartet.
    ```shell
    docker network create proxy
    docker compose up -d
    ```

## Konfiguration für neue Dienste

=== "nginx"
    Für das einbinden eines webbasierten Dienstes in nginx sind eine Reihe von Schritten erforderlich.

    Zunächst muss die Containerdefinition des Dienstes um ein entsprechendes Port-Bindung erweitert werden.
    Durch dieses wird der Port aus dem Container an das Hostsystem exposiert wird und lokal angesprochen werden kann.
    Dabei darf natürlich nur die linke Seite (hier 8081) verändert werden.

    !!! tipp
        Schon verwendete Ports lassen sich mit folgendem Befehl ermitteln:
        ```sh
        grep -oP "(?<=proxy_pass)[^;]*" /etc/nginx/sites-enabled/* | sed "s/ /\t/" | expand -t 30
        ```

        Zur leichteren Verwendung empfielt sich das hinzufügen folgender Funktion in der Datei `~/.bashrc`:
        ```bash
        function searchport {
            grep -oP "(?<=proxy_pass)[^;]*" /etc/nginx/sites-enabled/* | sed "s/ /\t/" | expand -t 30 | grep ${1:-.}
        }
        ```
        Neben der Möglichkeit alle Ports mit `searchport` aufzulisten, ergibt sich die Möglichkeit den ersetzen Parameter zu setzen (`searchport 8081`) um den zu einem Port gehörenden Domainnamen anzuzeigen.

    In der `docker-compose.yaml` des jeweiligen Dienstes muss demnach folgendes hinzugefügt werden:
    ```yaml
        ports:
          - "[::1]:8081:80"
    ```

    Anschließend muss ein TLS Zertifikat für die gewünschte Domain auf der, der Dienst erreichbar sein soll
    angefordert werden.

    ```shell
    # Beispielkonfiguration für Cloudflare DNS API
    CF_Token=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX acme.sh --issue --keylength ec-384 --dns dns_cf -d service.domain.de
    ```

    Optional kann nun eine eigene IPv6 Adresse für diesen virtual Host konfiguriert werden:

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

    Nun kann der V-Host unter dem Pfad `/etc/nginx/sites-available/service.domain.de` erstellt werden:

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

    Zum Abschluss kann die Konfiguration aktiviert, getestet und angewandt werden.

    ```shell
    ln -s /etc/nginx/sites-available/service.domain.de \
        /etc/nginx/sites-enabled/

    nginx -t && systemctl reload nginx
    ```


=== "Traefik"
    Für das einbinden eines webbasierten Dienstes in Traefik sind lediglich zwei Schritte notwendig.

    Zunächst muss das `proxy`-Netzwerk dem Container hinzugefügt werden. Dabei ist zu beachten, dass
    - sofern dieser mit anderen Containern in der gleichen Containerdefinition - interagieren muss,
    ebenfalls das `default`-Netzwerk benötigt, welches der Standardwert für Container ohne explizite
    Netzwerkkonfiguration ist:
    ```yaml
        networks:
        - "proxy"
        #- "default"
    ```

    Außerdem müssen die Docker Labels für das HTTP Routing gesetzt werden:
    ```yaml
        labels:
        - "traefik.enable=true"
        - "traefik.http.services.srv_service-name.loadbalancer.server.port=80"
        - "traefik.http.routers.r_service-name.rule=Host(`service.domain.de`)"
        - "traefik.http.routers.r_service-name.entrypoints=websecure"
    ```

    !!! warning "Warnung"
        Hierbei sollte unbedingt darauf geachtet werden, dass weder service (Präfix `srv_`),
        noch router-Bezeichnungen (Präfix `r_`) doppelt verwendet werden, da dies zu schwer
        bemerkbaren Fehlern führen kann.

        Außerdem sollte auf die korrekte Konfiguration des Service Ports geachtet werden (hier 80).
