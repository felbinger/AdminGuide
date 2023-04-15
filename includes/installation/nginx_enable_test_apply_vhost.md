### Konfiguration aktivieren, testen und anwenden.
Nun muss noch der Link zu `/etc/nginx/sites-enabled/` angelegt werden, 
bevor die Konfiguration von nginx getestet werden kann und anschließend
nginx neu geladen werden kann, sofern der Test keine Fehler ergeben hat:

```shell
ln -s /etc/nginx/sites-available/service.domain.de \
    /etc/nginx/sites-enabled/

nginx -t && systemctl reload nginx
```
