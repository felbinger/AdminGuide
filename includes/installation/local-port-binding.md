### Port-Binding von Dienst auf IPv6 Localhost (`::1`) des Hosts
Die Containerdefinition muss einen entsprechenden Eintrag erhalten, sodass der Port 
auf dem der Container den Dienst bereitstellt, auf dem Hostsystem lokal verfügbar ist.
Dabei darf natürlich nur die linke Seite (hier 8081) verändert werden.
```yaml
    ports:
      - "[::1]:8081:80"
```