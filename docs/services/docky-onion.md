# docky-onion

Um einen [tor hidden services](https://2019.www.torproject.org/docs/onion-services) mit docker zu verwenden, kann man
[docky-onion](https://github.com/use-to/docky-onion) verwenden, um jeden Dienst in [tor](https://www.torproject.org/)
erreichbar zu machen. Hier ein Beispiel: `docker-compose.yml` um [nginx](https://www.nginx.com/) 
als hidden service auf port `80` und `8080` zur verfügung zustellen:

```yaml
version: "3.9"

services:
  docky-onion:
    image: useto/docky-onion
    restart: always
    environment:
      # this forwards 80 and 8080 to web:80
      - "TOR_HIDDEN_SERVICE_WEB=80 web:80;8080 web:80"
    volumes:
      - "/srv/docky-onion:/var/lib/tor/hidden_services"

  web:
    image: nginx
    restart: always
    depends_on:
      - docky-onion
```

Nach dem Starten des Containers mit dem Befehl `docker compose up -d` wird docky-onion den nginx proxy im Tor-Netzwerk
erreichbar machen.
Jetzt können wir die `.onion`-Adresse mithilfe von `docker compose exec docky-onion lookup` nachschauen.
Die Ausgabe sollte wie folgt (oder ähnlich) aussehen:
```
WEB => j3c7wmyv6b3q3uvowetwwygb7h57k2bjhtnwp2zfamda2ij2vanyhmid.onion
```

MERKE: Man bekommt mehrere `.onion`-Adressen für jeden Dienst, welcher im Tor-Netzwerk erreichbar ist.
