# Jupiter

```yaml
  jupyter:
    image: jupyter/scipy-notebook
    restart: always
    ports: 
      - "[::1]:8000:8888"
    volumes:
      - "/srv/jupyter/work:/home/jovyan/work/"
    environment:
      - "JUPYTER_ENABLE_LAB=yes"
networks:
  proxy:
    external:
      name: proxy
```
You have to set a password for your Jupyter Environment. For this you have to put in a token which you can find in the logs
of your container with `docker-compose logs jupyter`. There is an example domain which ends with `?token=******`. 
You have to copy this token and create a password on the website with it.

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
