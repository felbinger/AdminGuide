# Jupyter

Jupyter Notebook ist eine interaktive Entwicklungsumgebung, die es Benutzern ermöglicht, Code zu schreiben und
auszuführen, um interaktive Datenanalysen und Visualisierungen durchzuführen.

```yaml
version: '3.9'

services:
  jupyter:
    image: jupyter/scipy-notebook
    restart: always
    environment:
      - "JUPYTER_ENABLE_LAB=yes"
    ports:
      - "[::1]:8000:8888"
    volumes:
      - "/srv/jupyter:/home/jovyan/work/"
```

=== "nginx"
    ```yaml
        ports:
        - "[::1]:8000:8888"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_jupyter.loadbalancer.server.port=8888"
          - "traefik.http.routers.r_jupyter.rule=Host(`jupyter.domain.de`)"
          - "traefik.http.routers.r_jupyter.entrypoints=websecure"
    ```

Nach dem Initialen Start von Jupyter Notebook befindet sich 
ein Link mit einem Access Token in den Containerlogs 
(`docker compose logs jupyter`), kopieren Sie diesen 
Token (`?token=******`) um ein Passwort auf der Website festzulegen.

Das Passwort kann auch mit folgendem Befehl zurückgesetzt werden:
```shell
docker compose exec jupyter jupyter server password
```
