# Grafana

Grafana ist ein Dienst, welcher zur Datenvisualisierung und Überwachung verwendet wird. 

```yaml
version: '3.9'

services:
  grafana:
    image: grafana/grafana
    restart: always
    #volumes:
    #  - "/srv/grafana/lib:/var/lib/grafana"
    #  - "/srv/grafana/etc:/etc/grafana"
    ports:
      - "[::1]:8000:3000"
```

Da der Container die, in den Volumes liegenden Daten, nicht kopiert müssen wir das zuvor manuell erledigen:

```shell
sudo mkdir -p /srv/grafana

sudo docker-compose up -d grafana

sudo docker cp grafana-grafana-1:/var/lib/grafana \
  /srv/grafana/lib

sudo docker cp grafana-grafana-1:/etc/grafana \
  /srv/grafana/etc

sudo chown -R 472:472 /srv/grafana/
```

Entfernen Sie anschließend die Kommentarzeichen vor den Volumes in der Containerdefinition (`docker-compose.yml`).

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:3000"
    ```

    ```nginx
    # /etc/nginx/sites-available/grafana.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name grafana.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/grafana.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/grafana.domain.de_ecc/grafana.domain.de.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
        ssl_session_tickets off;

        # modern configuration
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers off;

        # HSTS (ngx_http_headers_module is required) (63072000 seconds)
        add_header Strict-Transport-Security "max-age=63072000" always;

        # OCSP stapling
        ssl_stapling on;
        ssl_stapling_verify on;

        location / {
            proxy_pass http://[::1]:8000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    ```

=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_grafana.loadbalancer.server.port=3000"
          - "traefik.http.routers.r_grafana.rule=Host(`grafana.domain.de`)"
          - "traefik.http.routers.r_grafana.entrypoints=websecure"
    ```


Anschließend können wir den Container starten und uns unter der 
angegebene Domain mit den Zugangsdaten `admin`:`admin` anmelden.

Die nächsten Schritte sind die Einrichtung von Data Sources (z. B. 
[InfluxDB](https://adminguide.pages.dev/services/influxdb/), 
[Prometheus](https://adminguide.pages.dev/services/prometheus/), 
[Loki](https://grafana.com/oss/loki/)) und das Hinzufügen/Erstellen von 
Dashboards (z. B. [Node Exporter Full](https://grafana.com/grafana/dashboards/1860-node-exporter-full/))
([siehe: officially supported datasources](https://grafana.com/docs/grafana/latest/datasources/#supported-data-sources)).

Über die Umgebungsvariable `GF_INSTALL_PLUGINS` kann eine Liste von 
Plugins angegeben werden, welche für die Grafana Instanz aktiviert werden.

### LDAP Auth
Du kannst den ldap auth in `/srv/main/grafana/etc/grafana.ini` und `/srv/main/grafana/etc/ldap.toml` konfigurieren:
```ini
#################################### Auth LDAP ##########################
[auth.ldap]
enabled = true
;config_file = /etc/grafana/ldap.toml
;allow_sign_up = true
```

```toml
[log]
filters = "ldap:debug"

[[servers]]
host = "ldap"
port = 389
use_ssl = false
start_tls = false
ssl_skip_verify = false

bind_dn = "cn=admin,dc=domain,dc=de"
bind_password = 'S3cr3T'

search_filter = "(&(objectclass=person)(&(memberof=cn=grafana,ou=groups,dc=domain,dc=de))(uid=%s))"
search_base_dns = ["dc=domain,dc=de"]

[servers.attributes]
name = "givenName"
surname = "sn"
username = "cn"
member_of = "memberOf"
email =  "email"

[[servers.group_mappings]]
group_dn = "cn=admin,cn=grafana,ou=groups,dc=domain,dc=de"
org_role = "Admin"

[[servers.group_mappings]]
group_dn = "cn=editor,cn=grafana,ou=groups,dc=domain,dc=de"
org_role = "Editor"

[[servers.group_mappings]]
group_dn = "*"
org_role = "Viewer"
```

Alle Mitglieder von `cn=grafana,ou=groups,dc=domain,dc=de` bekommen die Leser Rolle, Mitglieder welche auch in der `cn=editor,cn=grafana,ou=groups,dc=domain,dc=de` bekommen die Bearbeitungs Rolle...

## OpenID / KeyCloak
Siehe: [janikvonrotz.ch/2020/08/27/grafana-oauth-with-keycloak-and-how-to-validate-a-jwt-token](https://janikvonrotz.ch/2020/08/27/grafana-oauth-with-keycloak-and-how-to-validate-a-jwt-token/)
