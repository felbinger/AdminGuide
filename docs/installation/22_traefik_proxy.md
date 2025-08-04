# Traefik mit eigenem Proxy

Zunächst wird die Containerdefinition im Verzeichnis `/home/admin/traefik/docker-compose.yml` angelegt:
```yaml
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

{% include-markdown "../../includes/installation/traefik/config.md" %}

{% include-markdown "../../includes/installation/traefik/docker-network.md" %}

{% include-markdown "../../includes/installation/traefik/new.md" %}
