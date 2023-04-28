# Backup

Während meiner Zeit als Administrator für Linux Systeme habe ich einige Skripte und Programme entwickelt
([PyBackup](https://github.com/felbinger/PyBackup),
[GBM](https://github.com/felbinger/GBM),
[DBM](https://github.com/felbinger/dbm)). Mittlerweile verwende ich für dateibasierte Sicherungen
hauptsächlich [borg backup](https://borgbackup.readthedocs.io/en/stable/).

Im Backup des Servers sollten zumindest die Containerdefinitionen `/home/admin` 
sowie Daten der Container (`/srv`) enthalten sein. Sofern nginx als Reverse
Proxy genutzt wird, ist auch eine Sicherung von `/etc/nginx/sites-availabe/` sinnvoll.

Sofern Datenbanken auf dem Server sind, ist ggf. das Exportieren dieser
vor einem Backup ebenfalls sinnvoll, um einen konsistenten Stand zu haben.
```shell
sudo docker compose \
  -f /home/admin/service/docker-compose.yml \
  exec postgres pg_dumpall -U service_name \
    > /home/backups/service_name_$(date "+%Y-%m-%d").sql
```