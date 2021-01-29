ShareLaTeX requires a redis and a mongodb instance!
```yaml
  paper:
    # use latest tag for setup, use your own image (tag: with-texlive-full) after installation 
    image: sharelatex/sharelatex:latest
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_paper.loadbalancer.server.port=80"
      - "traefik.http.routers.r_paper.rule=Host(`paper.domain.de`)"
      - "traefik.http.routers.r_paper.entrypoints=websecure"
      - "traefik.http.routers.r_paper.tls.certresolver=myresolver"
    volumes:
      - /srv/storage/paper/data:/var/lib/sharelatex
    environment:
      - "SHARELATEX_APP_NAME=ShareLaTeX"
      - "SHARELATEX_MONGO_URL=mongodb://mongo/sharelatex"
      - "SHARELATEX_REDIS_HOST=redis"
      - "REDIS_HOST=redis"
      - "ENABLED_LINKED_FILE_TYPES=url,project_file"
      - "ENABLE_CONVERSIONS=true"
      - "EMAIL_CONFIRMATION_DISABLED=true"
      - "TEXMFVAR=/var/lib/sharelatex/tmp/texmf-var"
      - "SHARELATEX_SITE_URL=https://paper.domain.de"
      - "SHARELATEX_NAV_TITLE=ShareLaTeX"
      - "SHARELATEX_LEFT_FOOTER=[]"
      - "SHARELATEX_RIGHT_FOOTER=[]"
      #- "SHARELATEX_HEADER_IMAGE_URL=http://somewhere.com/mylogo.png"
      #- "SHARELATEX_EMAIL_FROM_ADDRESS=team@sharelatex.com"
      #- "SHARELATEX_EMAIL_SMTP_HOST=smtp.mydomain.com"
      #- "SHARELATEX_EMAIL_SMTP_PORT=587"
      #- "SHARELATEX_EMAIL_SMTP_SECURE=false"
      #- "SHARELATEX_EMAIL_SMTP_USER="
      #- "SHARELATEX_EMAIL_SMTP_PASS="
      #- "SHARELATEX_EMAIL_SMTP_TLS_REJECT_UNAUTH=true"
      #- "SHARELATEX_EMAIL_SMTP_IGNORE_TLS=false"
      #- "SHARELATEX_CUSTOM_EMAIL_FOOTER=This system is run by department x"
    networks:
      - database
      - proxy

  # requirements for ShareLaTeX
  mongo:
    image: mongo:4.0
    restart: always
    volumes:
      - "/srv/storage/paper/mongo:/data/db"
    healthcheck:
      test: echo 'db.stats().ok' | mongo localhost:27017/test --quiet
      interval: 10s
      timeout: 10s
      retries: 5
    networks:
      - database

  redis:
    image: redis:5
    restart: always
    volumes:
      - "/srv/storage/paper/redis:/data"
    networks:
      - database
```

### Installation of texlive-full
!!! warning ""
    If you start the container using docker-compose, the image will be commited with all environment variables and labels.

1. Install `texlive-full`
   
    !!! warning ""
        Due to the fact, that this command will take a couple of house, I suggest you to execute it in a screen session.

    !!! warning ""
        The Image will take about 8 gigabytes after installation all additional packages.

    ```sh
    screen -AmdS latex-installation "docker-compose exec paper tlmgr update --self; tlmgr install scheme-full"
    ```

2. Save the current container filesystem as docker image with tag: `with-texlive-full`

    ```shell
    docker commit -m "installing all latex packages" $(docker-compose ps -q paper) sharelatex/sharelatex:with-texlive-full
    ```

3. Replace the image tag in your `docker-compose.yml` from `latest` to `with-texlive-full`

### Creating an user

Now you have to create an admin user by simply running this command:

```shell
docker-compose exec paper /bin/bash -c "cd /var/www/sharelatex; grunt user:create-admin --email=my@email.address"
```

Replace `my@email.address` with your email. You will now be given a password reset link with which you can initially set the password for the admin user.
