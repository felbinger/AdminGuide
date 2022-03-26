# Home

!!! warning ""
    This Admin Guide is being rewritten at the moment!

This document describes my current preferred method to make a virtual machine with web applications accessible behind the Cloudflare proxy.

Basically, I only make web-based applications available via IPv6. To ensure IPv4 reachability, and to be able to switch a web application firewall or page rules if necessary, the Cloudflare proxy is used.

Cloudflare connects to the web-based application on my server via IPv6. Using Origin Server Certificates, the connection is encrypted.

To ensure that the WAF / Page Rules cannot be bypassed, my web server expects a mTLS client certificate from the Cloudflare Origin Pull CA, the setup at Cloudflare is described here.

If more than one web based application are installed on a server, I assign myself a separate IPv6 address for each service. This makes blocking a single service in the firewall as well as debugging easier. Under Debian the network configuration in the file /etc/network/interfaces is extended as follows:

```
allow-hotplug eth0
iface eth0 inet dhcp

iface eth0 inet6 static
    # service 1 
    address 2001:db8::fdfd:dead:beef:affe/64
    gateway 2001:db8::1
    # service 2
    post-up ip -6 a add 2001:db8::fefe:dead:beef:affe/64 dev ens18    # <---- this line
    # service 3
    post-up ip -6 a add 2001:db8::ffff:dead:beef:affe/64 dev ens18    # <---- this line
```


## Create your Services

After you successfully installed your system, you can add the services you need.  
Before you add a new service think which stack fits best. It might be useful to create a new stack.

You can find a lot of services (e.g. Databases, Gameserver, Apps for Communication, Apps for File Storage, ...) in the navigation bar on the left side of the page.
Simply add them to your `docker-compose.yml` and modify the required attributes (e.g. passwords, domain name, routing configuration, ...).

### Environment Variables
I don't put environment variables in the `docker-compose.yml`, instead I create a `.<service_name>.env` file, in which all environment variables are defined.
Afterwards I add this environment file using `env_file: .<service_name>.env` to the service, defined in the `docker-compose.yml`.
The main reason for that is, to prevent password leaks: e.g. screensharing, or if you send someone your service definition

## Tools

### [ctop](https://ctop.sh/)

Simple commandline monitoring tool for docker containers:

```bash
sudo wget https://github.com/bcicen/ctop/releases/download/0.7.6/ctop-0.7.6-linux-amd64 \
  -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
```

### Docker Network Viewer

A simple tool to show docker networks:

```bash
sudo apt install apt-transport-https ca-certificates curl gnupg
  
curl -fsSL https://m4rc3l.de/static/deb-repo.pem | sudo gpg --dearmor -o /usr/share/keyrings/m4rc3l-deb-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/m4rc3l-deb-keyring.gpg] http://deb.m4rc3l.de/ all main" \
  | sudo tee /etc/apt/sources.list.d/m4rc3l.list > /dev/null

sudo apt update
sudo apt install docker-network-viewer
```

```bash
sudo wget https://github.com/MarcelCoding/docker-network-viewer/releases/download/v1.1.1/docker-network-viewer \
  -O /usr/local/bin/dnv
sudo chmod +x /usr/local/bin/dnv
```

```sh
$ sudo dnv
bridge			172.17.0.0/16
proxy			  192.168.0.0/24
database		192.168.1.0/24
monitoring	192.168.2.0/24
main			  192.168.100.0/24
storage			192.168.101.0/24
comms			  192.168.102.0/24
jitsi			  192.168.103.0/24
games			  192.168.104.0/24
```
