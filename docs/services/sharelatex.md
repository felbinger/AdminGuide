# ShareLaTeX

```yaml
version: '3.9'

services:
  sharelatex:
    # use latest tag for setup, use your own image (tag: with-texlive-full) after installation 
    image: sharelatex/sharelatex
    restart: always
    env_file: .sharelatex.env
    environment:
      - "SHARELATEX_APP_NAME=ShareLaTeX"
      - "SHARELATEX_REDIS_HOST=redis"
      - "REDIS_HOST=redis"
      - "SHARELATEX_MONGO_URL=mongodb://mongo/sharelatex"
      #- "SHARELATEX_EMAIL_SMTP_HOST=smtp.mydomain.com"
      #- "SHARELATEX_EMAIL_SMTP_PORT=587"
      #- "SHARELATEX_EMAIL_SMTP_SECURE=false"
      #- "SHARELATEX_EMAIL_SMTP_TLS_REJECT_UNAUTH=true"
      #- "SHARELATEX_EMAIL_SMTP_IGNORE_TLS=false"
      - "ENABLED_LINKED_FILE_TYPES=url,project_file"
      - "ENABLE_CONVERSIONS=true"
      - "EMAIL_CONFIRMATION_DISABLED=true"
      - "TEXMFVAR=/var/lib/sharelatex/tmp/texmf-var"
      - "SHARELATEX_SITE_URL=https://overleaf.domain.de"
      - "SHARELATEX_NAV_TITLE=ShareLaTeX"
      - "SHARELATEX_LEFT_FOOTER=[]"
      - "SHARELATEX_RIGHT_FOOTER=[]"
      #- "SHARELATEX_HEADER_IMAGE_URL=http://somewhere.com/mylogo.png"
      #- "SHARELATEX_EMAIL_FROM_ADDRESS=team@sharelatex.com"
      #- "SHARELATEX_CUSTOM_EMAIL_FOOTER=This system is run by department x"
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/sharelatex/data:/var/lib/sharelatex"

  mongo:
    image: mongo
    restart: always
    volumes:
      - "/srv/sharelatex/mongo:/data/db"
    healthcheck:
      test: echo 'db.stats().ok' | mongo localhost:27017/test --quiet
      interval: 10s
      timeout: 10s
      retries: 5

  # version must be locked to 5, otherwise sharelatex wont work
  redis:
    image: redis:5
    restart: always
    volumes:
      - "/srv/sharelatex/redis:/data"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_sharelatex.loadbalancer.server.port=80"
          - "traefik.http.routers.r_sharelatex.rule=Host(`sharelatex.domain.de`)"
          - "traefik.http.routers.r_sharelatex.entrypoints=websecure"
    ```

```shell
# .sharelatex.env
#SHARELATEX_EMAIL_SMTP_USER=
#SHARELATEX_EMAIL_SMTP_PASS=
```

### Installation of texlive-full
!!! warning ""
    If you start the container using docker-compose, the image will be committed with all environment variables and labels.

1. Install `texlive-full`
   
    !!! warning ""
        Due to the fact, that this command will take a couple of house, I suggest you to execute it in a screen session.

    !!! warning ""
        The Image will take about 8 gigabytes after installation all additional packages.

    ```sh
    screen -AmdS latex-installation "docker-compose exec sharelatex tlmgr update --self; tlmgr install scheme-full"
    ```

2. Save the current container filesystem as docker image with tag: `with-texlive-full`

    ```shell
    docker commit -m "installing all latex packages" $(docker-compose ps -q sharelatex) sharelatex/sharelatex:with-texlive-full
    ```

3. Replace the image tag in your `docker-compose.yml` from `latest` to `with-texlive-full`

### Creating a user

Now you have to create an admin user by simply running this command:

```shell
docker-compose exec sharelatex /bin/bash -c "cd /var/www/sharelatex; grunt user:create-admin --email=my@email.address"
```

Replace `my@email.address` with your email. You will now be given a password reset link with which you can initially set the password for the admin user.

### Deleting an user

User can be deleted via the following command, projects will also be deleted so be careful with this.

```shell
docker-compose exec sharelatex /bin/bash -c "cd /var/www/sharelatex; grunt user:delete --email=my@email.address"
```

Change here the email `my@email.address` with the email of the user you want to delete.