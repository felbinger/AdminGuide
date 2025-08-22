Für das Backup des Server verwenden wir [BorgBackup2](https://borgbackup.readthedocs.io/en/master/index.html).
Wir empfehlen in dieser Anleitung das Sichern verschiedenster in diesem Guide angelegten und regelmäßig verwendeten
Verzeichnisse. Gerne darf man mehr Verzeichnisse speichern, denn "kein Backup, kein Mitleid!".

### Installation
```shell
sudo apt install borgbackup2
```

### Backup Verzeichnis
In diesem Guide stellen wir die lokale Speichern des Backups vor, da diese jeder mit einem Server verwenden kann.
Dennoch empfehlen dass Sichern des Backups auf einem dedizierten Gerät (StorageBox, anderer Server, NAS, ...).

#### Erstellung des Backup Verzeichnisses
Zu der lokalen Sicherung des Backups verwenden wir einen Ordner im `/home` Verzeichniss und geben ihm die selben Rechte
wie dem `/home/admin` Verzeichniss, damit alle Administrator des Servers auf dieses Backup zugreifen können.

```shell
sudo mkdir -m 770 /home/backups
sudo chown root:admin /home/backups
```

#### Initialisierung des Verzeichnisses als Backupverzeichnis
```shell
borg2 -r /home/backups rcreate -e repokey-blake2-chacha20-poly1305
```

### Sichern von kritischen Verzeichnissen
Wie oben schon beschrieben empfehlen wir hier das Sichern von den Verzeichnissen welche wir hier im Guide erstellen.
Man sichert aber lieber zu viel, als zu wenig!

Der Aufbau des Sicherungsbefehl ist folgender:
```shell
borg2 -r /backup/verzeichnis create name_des_archives_in_borg /zu/sicherndes/verzeichnis
```


Um nicht jedes Verzeichnis einzeln auszuführen, haben wir uns dafür ein kleines Script geschrieben. Wir empfehlen dieses
Script in einem Screen auszuführen, da je nach Dateigröße das intiale Backup bis zu mehreren Stunden dauern kann

!!! info ""
    Mit sudo ausführen!

```shell
### backup.sh
declare -A map=(
  ["admin"]="/home/admin"
  ["srv"]="/srv"
  ["nginx"]="/etc/nginx/sites-available"
  ["network"]="/etc/network/"
  ["certificates"]="/root/.acme"
)
for name in ${!map[@]}; do 
  paths="${map[${name}]}"
  borg2 -r /home/backups create "${name}" "${paths}"
done
```


Hinweis: Wenn man das Script als root User ausführt und das Script in folgender Reihenfolge ausführt, braucht man nicht
für jedes Verzeichnis den Key neu eingeben

```shell
sudo -s
BORG_PASSPHRASE=Die_eindeutige_passphrase bash backup.sh
```