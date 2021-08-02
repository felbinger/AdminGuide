# Jupiter

## Host Your JupyterLab Server
Read the [Documentation](https://github.com/jupyter/docker-stacks).

### docker-compose.yml
First you have to add the configuration to your `docker-compose.yml`
```yaml
  jupyter:
    image: jupyter/scipy-notebook
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_jupyter.loadbalancer.server.port=8888"
      - "traefik.http.routers.r_jupyter.rule=Host(`jupyter.domain.tld`)"
      - "traefik.http.routers.r_jupyter.entrypoints=websecure"
      - "traefik.http.routers.r_jupyter.tls=true"
      - "traefik.http.routers.r_jupyter.tls.certresolver=myresolver"
    networks:
      - proxy
    volumes:
      - /srv/jupyter/work:/home/jovyan/work/
    environment:
      - "JUPYTER_ENABLE_LAB=yes"
networks:
  proxy:
    external:
      name: proxy
```
Then just run the container and watch on the JupyterLab Website. You have to set a password
for your Jupyter Environment. For this you have to put in a token which you can find in the logs
of your container with `docker-compose logs jupyter`. There is an example domain which ends with
`?token=******`. You have to copy this token and create a password on the website with it.

### Reset Password
If you have forgotten your password, you can sign in with the token or you can change the
password. To change the password you go into the container terminal with
```bash
docker-compose exec jupyter bash
```
and then you type
```bash
jupyter server password
```
There you can change your password

### Fix the permissions
You have to adjust the permissions for your `/work` folder. You do this with this command
```bash
chown 1000:1000 /srv/jupyter/work/
```
