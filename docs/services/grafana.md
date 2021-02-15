```yaml
  grafana:
    image: grafana/grafana
    restart: always
    env_file: .grafana.env
    #volumes:
    #  - "/srv/main/grafana/lib:/var/lib/grafana"
    #  - "/srv/main/grafana/etc:/etc/grafana"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_grafana.loadbalancer.server.port=3000"
      - "traefik.http.routers.r_grafana.rule=Host(`grafana.domain.de`)"
      - "traefik.http.routers.r_grafana.entrypoints=websecure"
    networks:
      - monitoring
      - proxy
```

Unfortunately you need to copy some file out of the container before you can use grafana:
```bash
sudo mkdir -p /srv/main/grafana

# start the container without volumes
sudo docker-compose up -d grafana

sudo docker cp main_grafana_1:/var/lib/grafana \
  /srv/main/grafana/lib

sudo docker cp main_grafana_1:/etc/grafana \
  /srv/main/grafana/etc

# adjust permissions
sudo chown -R 472:472 /srv/main/grafana/

sudo docker-compose rm -fs grafana
```

Next you can remove the comments in front of the volumes and start up the container.  
The default login for grafana is `admin`:`admin`.

### Datasources and Dashboards
Finally you can add datasources and create dashboards:

!!! info ""
    Checkout the [officially supported datasources](https://grafana.com/docs/grafana/latest/datasources/#supported-data-sources)

![Datasources](../img/services/grafana_datasources.png?raw=true){: loading=lazy }

![Dashboard](../img/services/grafana_dashboard.png?raw=true){: loading=lazy }


### Plugins
You may specify a list of plugins which you would like to install in the `.grafana.env`:
```
GF_INSTALL_PLUGINS=grafana-piechart-panel
```
