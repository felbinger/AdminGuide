### Optional: Eigene IPv6 Adresse für Virtual Host konfigurieren
Sofern eine eigene IPv6 Adresse für diesen Dienst verwendet werden soll,
wird diese der entsprechenden Netzwerkschnittstelle hinzugefügt, sodass 
diese in nginx verwendet werden kann. 

=== "Debian"
    ```shell
    # /etc/network/interfaces
    
    # ...
    
    iface eth0 inet6 static
        # ipv6 address of the host
        address 2001:db8:1234:5678::1/64
        gateway 2001:db8::1

        # service.domain.de
        post-up ip -6 a add 2001:db8:1234:5678:5eca:dc9d:fd4e:6564/64 dev $IFACE
        pre-down ip -6 a del 2001:db8:1234:5678:5eca:dc9d:fd4e:6564/64 dev $IFACE
    ```

=== "Ubuntu"
    Da Ubuntu `netplan` zum Konfigurieren der Netzwerkeschnittstellen verwendet, muss die entsprechende Konfiguration im 
    Verzeichnis `/etc/netplan` angepasst werden.
    Die Konfigurationsdatei sollte ungefähr wie folgt aussehen:
    ```yaml
    network:
        version: 2
        renderer: networkd
        ethernets:
            enp1s0:
                addresses:
                    - 10.10.10.2/24
                    - 2001:db8::5/64
                dhcp4: no
                routes:
                    - to: 0.0.0.0/0
                    via: 10.10.10.1
                    - to: ::/0
                    via: 2001:db8::1
                nameservers:
                    addresses: [10.10.10.1, 1.1.1.1, 2001:470:20::2]
    ```
    Wenn die Konfigurationsdatei gefunden wurde, fügt man in dem `addresses` Abschnitt die neue IPv6 Adresse wie 
    folgt hinzu:
    ```yaml
    addresses:
        ...
        - 2001:db8:4a:90a:d8d5:dbf4:fd80:8f80
    ```
