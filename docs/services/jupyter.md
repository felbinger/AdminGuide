# Jupiter

!!! warning ""
	This Admin Guide is being rewritten at the moment!



```yaml
version: '3.9'

services:
  jupyter:
    image: jupyter/scipy-notebook
    restart: always
    environment: .jupyter.env
    ports: 
      - "[::1]:8000:8888"
    volumes:
      - "/srv/jupyter/work:/home/jovyan/work/"
```

```shell
# .jupyter.env
JUPYTER_ENABLE_LAB=yes
```

You have to set a password for your Jupyter Environment. For this you have to put in a token which you can find in the logs
of your container with `docker-compose logs jupyter`. There is an example domain which ends with `?token=******`. 
You have to copy this token and create a password on the website with it.

### Reset Password
If you have forgotten your password, you can sign in with the token or you can change the
password. To change the password you go into the container terminal with
```shell
docker-compose exec jupyter bash
```
and then you type
```shell
jupyter server password
```
There you can change your password

### Fix the permissions
You have to adjust the permissions for your `/work` folder. You do this with this command
```shell
chown 1000:1000 /srv/jupyter/work/
```
