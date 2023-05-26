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
        post-up ip -6 a add 2001:db8:1234:5678:5eca:dc9d:fd4e:6564/64 dev eth0
    ```

=== "Ubuntu"
    Unter Ubuntu ist es etwas anders. Von Ubuntu aus hat man in `/etc/netplan` eine `50-cloud-init.yaml`, wenn diese nicht
    existiert, dann muss man schauen, welche Datei die Konfigurationsdatei für das Netzwerk ist. 
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
    Wenn die Konfigurationsdatei gefunden wurde, muss man in dem `addresses` Abschnitt die neue IPv6 Adresse wie folgt
    hinzufügen:
    ```yaml
    addresses:
        ...
        - 2001:db8:4a:90a:d8d5:dbf4:fd80:8f80
    ```
