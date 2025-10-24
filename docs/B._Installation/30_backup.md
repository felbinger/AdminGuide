# 3. Backup

Für das Backup des Server kann [BorgBackup2](https://borgbackup.readthedocs.io/en/master/index.html) verwendet werden.

### Installation
```shell
sudo apt install borgbackup2
```

### Backup Verzeichnis
In diesem Guide stellen wir die lokale Speicherung des Backups vor, da diese jeder mit einem Server verwenden kann.
Dennoch empfehlen wir das Sichern des Backups auf einem dedizierten Gerät (StorageBox, anderer Server, NAS, ...).

#### Erstellung des Backup Verzeichnisses
Zu der lokalen Sicherung des Backups verwenden wir einen Ordner im `/home` Verzeichnis und geben ihm die selben Rechte
wie dem `/home/admin` Verzeichnis, damit alle Administrator des Servers auf dieses Backup zugreifen können.

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

Um nicht jedes Verzeichnis einzeln auszuführen, haben wir uns dafür ein kleines Skript geschrieben. Wir empfehlen dieses
Skript in einem Screen auszuführen, da je nach Dateigröße das intiale Backup bis zu mehreren Stunden dauern kann.

Hierbei sollte beachtet werden, dass das Skript zwangsläufig unter dem root-Nutzer ausgeführt werden muss, sodass voller
Zugriff auf alle Pfade besteht.

!!! note
    Die folgenden Verzeichnisse sind jene, die im Rahmen dieses Guides aktiv verwendet werden.

    Selbstverständlich können auch zusätzliche Pfade in das Backup aufgenommen werden – denn: „Kein Backup, kein Mitleid!“

```shell
# backup.sh
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


!!! note
    Die Umgebungsvariable BORG_PASSPHRASE kann beim Aufruf des Skripts verwendet werden,
    um das gleiche Passwort für jedes Verzeichnis zu verwenden.

    Hierbei ist zu beachten, dass das Skript als root Nutzer ausgeführt werden muss,
    da sonst erforderliche Privilegien zur Durchführung des Backups fehlen.

```shell
sudo -s
BORG_PASSPHRASE=s3cr3t-s3cur3-p4ssw0rd bash backup.sh
```