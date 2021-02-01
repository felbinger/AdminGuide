# Traefik
Add the following configuration to your `docker-compose.yml` in the main stack:
```yaml
  traefik:
    image: traefik:v2.4
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=proxy"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=admin@domain.de"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
      #- "--certificatesresolvers.myresolver.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
      - "--providers.file.filename=/configs/dynamic.yml"
      #- "--log.level=DEBUG"
      - "--accesslog=true"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_traefik.loadbalancer.server.port=8080"
      - "traefik.http.routers.r_traefik.rule=Host(`traefik.domain.de`)"
      - "traefik.http.routers.r_traefik.entrypoints=websecure"
      - "traefik.http.routers.r_traefik.tls=true"
      - "traefik.http.routers.r_traefik.tls.certresolver=myresolver"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/srv/main/traefik/letsencrypt:/letsencrypt"
      - "/srv/main/traefik/dynamic.yml:/configs/dynamic.yml"
      - "/etc/localtime:/etc/localtime:ro"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    networks:
      - proxy
```

Create the file `/srv/main/traefik/dynamic.yml` to require TLS version 1.2 or higher (currently only TLS 1.3):
```yaml
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

You also need a webserver for static content e.g. your [error pages](https://github.com/felbinger/AdminGuide/tree/master/error_pages): 
```yaml
  static:
    image: nginx:stable-alpine
    restart: always
    labels:
      # BASIC CONFIGURATION
      - "traefik.enable=true"
      - "traefik.http.services.srv_static.loadbalancer.server.port=80"

      # ERROR PAGES
      - "traefik.http.middlewares.error40x.errors.status=403-404"
      - "traefik.http.middlewares.error40x.errors.service=srv_static"
      - "traefik.http.middlewares.error40x.errors.query=/error/{status}.html"
      - "traefik.http.middlewares.error30x.errors.status=300-308"
      - "traefik.http.middlewares.error30x.errors.service=srv_static"
      - "traefik.http.middlewares.error30x.errors.query=/error/30x.html"

      # HSTS
      - "traefik.http.middlewares.mw_hsts.headers.frameDeny=true"
      - "traefik.http.middlewares.mw_hsts.headers.contentTypeNosniff=true"
      - "traefik.http.middlewares.mw_hsts.headers.browserXssFilter=true"
      - "traefik.http.middlewares.mw_hsts.headers.forceSTSHeader=true"
      - "traefik.http.middlewares.mw_hsts.headers.sslRedirect=true"
      - "traefik.http.middlewares.mw_hsts.headers.stsPreload=true"
      - "traefik.http.middlewares.mw_hsts.headers.stsSeconds=315360000"
      - "traefik.http.middlewares.mw_hsts.headers.stsIncludeSubdomains=true"
      - "traefik.http.middlewares.mw_hsts.headers.customRequestHeaders.X-Forwarded-Proto=https"

      # DOMAIN ROOT CONTENT
      - "traefik.http.routers.r_static_root.rule=HostRegexp(`domain.de`, `{subdomain:[a-z0-9]+}.domain.de`)"
      - "traefik.http.routers.r_static_root.entrypoints=websecure"
      - "traefik.http.routers.r_static_root.tls=true"
      - "traefik.http.routers.r_static_root.tls.certresolver=myresolver"
      - "traefik.http.routers.r_static_root.priority=10"
      - "traefik.http.middlewares.mw_static_root.addprefix.prefix=/domain_root/"
      - "traefik.http.routers.r_static_root.middlewares=mw_hsts@docker,mw_static_root@docker,error40x@docker,error30x@docker"
    volumes:
      - "/srv/main/static/webroot:/usr/share/nginx/html/"
    networks:
      - proxy
```

You should also add your domain to the [HSTS Preload List](https://hstspreload.org/), all subdomains need to be reachable using a secure connection, so you need a wildcard certificate for this.

Let's do a [ssltest](https://www.ssllabs.com/ssltest) to see how good we are:
![Picture of the ssltest result](../img/services/traefik_ssllabs_test.png?raw=true){: loading=lazy }

### Wildcard Certificates
1. Modify the command section of your traefik, to setup dnschallenge (remove `....tlschallenge=true`):
   ```yaml
         # e.g. for cloudflare
         - "--certificatesresolvers.myresolver.acme.dnschallenge=true"
         - "--certificatesresolvers.myresolver.acme.dnschallenge.provider=cloudflare"
         - "--certificatesresolvers.myresolver.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
   ```
2. Modify the environment section ([you can also use docker secrets](https://doc.traefik.io/traefik/user-guides/docker-compose/acme-dns/#use-secrets)) of your traefik, to provide the required credentials for you dns api (checkout [the list of providers](https://doc.traefik.io/traefik/https/acme/#providers)).
3. Configure the wildcard certificate for your services (e.g. the traefik dashboard in the labels section of the traefik service):
   ```yaml
         - "traefik.http.routers.r_traefik.tls.domains[0].main=domain.de"
         - "traefik.http.routers.r_traefik.tls.domains[0].sans=*.domain.de"
   ```

### Authentication Middlewares
Traefik offers a lot of authentication middlewares (e.g. [BasicAuth](https://doc.traefik.io/traefik/middlewares/basicauth/), [ForwardAuth](https://doc.traefik.io/traefik/middlewares/forwardauth/) (if you can provide a authentication service))

#### Basic Auth
We are going to add a new router to our static service, which will provide files for download, behind an basic auth.
First we have to extend our traefik service, with the htpasswd file for the service. This can be done by simply adding the following volume:
```yaml
...
volumes:
  ...
  - "/srv/main/traefik/webfiles.htpasswd:/htpasswd/webfiles"
  ...
...
```
You can create the htpasswd file using the htpasswd utility from the apache2-utils package (at least on debian based operating systems).
```
apt install -y apache2-utils
htpasswd -c /srv/main/traefik/webfiles.htpasswd -c <username>
```

Now we can add the new router to our static service:
```yaml
    ...
    labels:
      ...
      - "traefik.http.routers.r_static_files.rule=Host(`files.domain.de`)"
      - "traefik.http.routers.r_static_files.entrypoints=websecure"
      - "traefik.http.routers.r_static_files.tls=true"
      - "traefik.http.routers.r_static_files.tls.certresolver=myresolver"
      - "traefik.http.middlewares.mw_static_files.addprefix.prefix=/static_files/"
      - "traefik.http.middlewares.mw_static_files_auth.basicauth.usersfile=/htpasswd/webfiles"
      - "traefik.http.routers.r_static_files.middlewares=mw_static_files@docker,mw_static_files_auth@docker,error40x@docker,error30x@docker"
    ...
```

We also need to enable directory listing by creating the configuration for this uri:
```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    location /static_files {
        root /usr/share/nginx/html;
        autoindex on;
    }
}
```

Don't forget to add the created configuration to the volume section of the static service:
```yaml
...
volumes:
  ...
  - "/srv/main/static/nginx.conf:/etc/nginx/conf.d/default.conf"
...
```

### Redirect Middleware
You can also redirect a domain directly to another resource (e.g. your external webinterface of your mailserver):
```yaml
      - "traefik.http.routers.r_redirect.rule=Host(`domain.de`)"
      - "traefik.http.routers.r_redirect.entrypoints=websecure"
      - "traefik.http.routers.r_redirect.tls=true"
      - "traefik.http.routers.r_redirect.tls.certresolver=myresolver"
      - "traefik.http.middlewares.mw_redirect.redirectregex.regex=https://domain.de"
      - "traefik.http.middlewares.mw_redirect.redirectregex.replacement=https://redirecteddomain.de"
      - "traefik.http.middlewares.mw_redirect.redirectregex.permanent=true"
      - "traefik.http.routers.r_redirect.middlewares=mw_redirect@docker,error40x@docker,error30x@docker"
```
