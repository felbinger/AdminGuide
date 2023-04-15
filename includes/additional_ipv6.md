#### Optional: Eigene IPv6 Adresse für Virtual Host konfigurieren
Sofern eine eigene IPv6 Adresse für diesen Dienst verwendet werden soll,
wird diese der entsprechenden Netzwerkschnittstelle hinzugefügt, sodass 
diese in nginx verwendet werden kann. 

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