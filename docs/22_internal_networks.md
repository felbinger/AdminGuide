# Internal Networks

Die im AdminGuide aufgeführten Services erhalten grundsätzlich alle ihre eigene Datenbank. Dies erfordert zum einen mehr
Ressourcen, als eine zentrale Datenbank, zum anderen erfordert es beim Exportieren der Datenbanken für ein Backup die
Behandlung mehrerer Datenbankserver.

Wenn man eine Datenbank für alle Dienste nutzen möchte so sollte dieser als eigener Service definiert werden und über ein
docker-internes Netzwerk mit den anderen Diensten kommunizieren.

![Schematic with internal networks](img/internal_networks.png){: loading=lazy }

Das interne Netzwerk kann mit dem folgenden Befehl erstellt werden:
```shell
sudo docker network create --subnet 172.20.255.0/24 database
```

## Beispielkonfiguration
In diesem Beispiel wird eine zentrale MariaDB Datenbank verwendet.
Die beiden Diensten (Nextcloud, HedgeDoc) nutzen ein docker-internes 
Netzwerk zur Kommunikation mit der Datenbank. 

### MariaDB
```yaml
# /home/admin/mariadb/docker-compose.yml
version: '3.9'

services:
  mariadb:
    image: mariadb   
    restart: always
    env_file: .mariadb.env
    volumes:
      - "/srv/mariadb:/var/lib/mysql"    
    networks:
      - "database"

networks:
  database:
    external: true
```

### HedgeDoc
```yaml
# /home/admin/hedgedoc/docker-compose.yml
version: '3.9'

services:
  hedgedoc:
    image: quay.io/hedgedoc/hedgedoc
    restart: always
    env_file: .hedgedoc.env
    ports:
      - "[::1]:8000:3000"
    volumes:
      - "/srv/hedgedoc/uploads:/hedgedoc/public/uploads"
    networks:
      - "database"

networks:
  database:
    external: true
```

### Nextcloud
Im Falle von Nextcloud wird der `nextcloud` Container neben dem 
`database` Netzwerk auch noch in das `default` Netzwerk aufgenommen.
Dieses Netzwerk ermöglicht die Kommunikation mit der in der gleichen
Containerdefinition existierenden Redis Instanz. Wird in einem Service
kein Netzwerk angegeben (wie dies beim `redis` Service der Fall ist)
wird dieser in das `default` Netzwerk aufgenommen.

```yaml
# /home/admin/nextcloud/docker-compose.yml
version: '3.9'

services:
  redis:
    image: redis
    restart: always 

  nextcloud:
    image: nextcloud
    restart: always
    env_file: .nextcloud.env
    volumes:
      - "/srv/nextcloud:/var/www/html"
    ports:
      - "[::1]:8001:80"
    networks:
      - "default"
      - "database"

networks:
  default:
  database:
    external: true
```
