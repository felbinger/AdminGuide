# 1. Basisinstallation

!!! note
    Jeder, der diese Informationssammlung nutzt, sollte in der Lage sein, seinen
    Linux Server grundlegend einzurichten und abzusichern. Daher verzichte ich hier
    auf Standardanleitungen und stelle lediglich die spezifischen Konzepte vor.

## Admin Gruppe
Ich gehe grundsätzlich davon aus, dass ich auf keinem System der alleinige Administrator
bin. Auf all meinen Systemen existiert daher eine eigene Admin-Gruppe, die Zugriff auf das
Verzeichnis `/home/admin` besitzt. Diese Gruppe dient als zentraler Ablageort für
Container-Definitionen, Umgebungsvariablen-Dateien und Skripte.

!!! warning "`admin` vs. `adm`"
    In vielen Linux-Distributionen – unter anderem auch in Debian – existiert
    standardmäßig die Gruppe `adm`. Sie ist für Aufgaben der Systemüberwachung
    vorgesehen und gewährt ihren Mitgliedern erweiterte Leserechte auf zahlreiche
    Logdateien im Verzeichnis /var/log.

    Für den hier beschriebenen Anwendungsfall ist die Nutzung dieser Gruppe jedoch
    ausdrücklich nicht vorgesehen, da sie administrative Berechtigungen über den
    eigentlichen Bedarf hinaus gewährt und somit ein potenzielles Sicherheitsrisiko
    darstellen kann.

```shell
groupadd -g 1100 admin
mkdir -m 770 /home/admin
chown root:admin /home/admin
```

Die personalisierten Benutzerkonten der Systemadministratoren werden zusätzlich
zur Mitgliedschaft in der Gruppe `sudo` auch der Gruppe `admin` hinzugefügt.

```shell
adduser nicof2000
usermod -aG sudo,admin nicof2000
```

## Docker
Die Installation von Docker ist in der offiziellen [Dokumentation](https://docs.docker.com/engine/install/debian/)
bereits sehr gut beschrieben. Zusätzlich richten wir einen Alias ein, um uns die wiederholte
Eingabe von `sudo docker compose` zu ersparen.
```shell
curl -fsSL https://get.docker.com | sudo bash
echo 'alias dc="sudo docker compose "' >> ~/.bashrc
```
