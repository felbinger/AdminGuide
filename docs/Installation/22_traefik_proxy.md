# Traefik mit eigenem Proxy

Zunächst wird die Containerdefinition im Verzeichnis `/home/admin/traefik/docker-compose.yml` angelegt:
```yaml
version: "3.9"

service:
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
      - "[::]:80:80"
      - "[::]:443:443"
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
      minVersion: VersionTLS12
      sniStrict: true
      cipherSuites:
        # TLS 1.3
        - TLS_AES_256_GCM_SHA384
        - TLS_CHACHA20_POLY1305_SHA256
        - TLS_AES_128_GCM_SHA256
        # TLS 1.2
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
```

Anschließend legen wir das `proxy` Docker Netzwerk an und starten Traefik.
```shell
docker network create proxy
docker compose up -d
```

### Konfiguration für neue Dienste
Für das einbinden eines webbasierten Dienstes in Traefik sind lediglich zwei Schritte notwenig.

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

!!! warning ""
    Hierbei sollte umbedingt darauf geachtet werden, dass weder service (Präfix `srv_`), 
    noch router-Bezeichnungen (Präfix `r_`) doppelt verwendet werden, da dies zu schwer
    bemerkbaren Fehlern führen kann.

    Außerdem sollte auf die korrekte Konfiguration des Service Ports geachtet werden (hier 80). 