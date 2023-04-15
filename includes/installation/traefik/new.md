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