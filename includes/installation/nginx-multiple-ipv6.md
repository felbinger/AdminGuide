### IPv6 Adresse pro Virtual-Host
Sofern geplant ist, jedem Virtual Host eine eigene IPv6 Adresse zu geben empfielt sich
den nginx systemd-Service um einige Sekunden zu verzögern, sodass sichergestellt werden 
kann, dass das System die IPv6 Adressen der Netzwerkschnittstelle bereits hinzugefügt hat.
Dieses Verfahren wurde auch [hier](https://docs.ispsystem.com/ispmanager-business/troubleshooting-guide/if-nginx-does-not-start-after-rebooting-the-server) beschrieben.

![Result of `systemctl status nginx`](../../docs/img/nginx/nginx-failed-ipv6-not-assignable.png){: loading=lazy }

Dazu muss in der Datei `/lib/systemd/system/nginx.service` vor der ersten `ExecStartPre` Zeile folgendes hinzugefügt werden:
```shell
# make sure the additional ipv6 addresses (which have been added with post-up) 
# are already on the interface (only required for enabled nginx service on system boot)
ExecStartPre=/bin/sleep 5
```