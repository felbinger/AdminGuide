We will group the services in different "stacks" to manage them, this way we can change specific things without taking all services offline. Furthermore we will use one docker network per stack to make sure, that each container is only able to communicate with other containers which it really needs.

## Getting Started

First, let's add the default directories into the admin directory:

```bash
mkdir -p /home/admin/{services,images,tools,docs}/
```

|   name   |                 description                    |
|----------|------------------------------------------------|
| services | contains the `docker-compose` and `.env` files |
| images   | contains the data for custom docker images     |
| tools    | contains various tools                         |
| docs     | contains the documentations of you server      |

For each stack we will create, we want to have a directory in `/home/admin/services/`, `/home/admin/images/` and `/srv/`:

* The directory in `/home/admin/services/` contains the `docker-compose.yml` and `.env` files. Which is later used in the `docker-compose.yml` as `env_file`.
* The directory in `/home/admin/images/` contains the source files for the docker image if we have to build the image on the server.
* The directory in `/srv/` is used to store persistent data for the stack (docker volumes).

We will also create multiple docker networks, to give the containers the ability to communicate with each other.

- Helper networks (for communitation between diffrent stacks: e.g. database, proxy, monitoring, ...) start at `192.168.0.0/24`
- Stack networks (one network for each stack) start at `192.168.100.0/24`

!!! note ""
    Note that a network with the submask 255.255.255.0 (cidr notation is 24) can only contain 254 hosts.
    You have to adjust your network size to your needs.

    Remember the formular: $2^{32-x}-2$ where $x$ is your submask in cidr notation  
    (e.g. with $24$: $2^{32−24}−2=254$; or with $20$: $2^{32−20}−2=4094$ usable adresses)

| Name       | Subnet           | Usage                                                      |
| :--------- | :--------------- | :--------------------------------------------------------- |
| Proxy      | 192.168.0.0/24   | Container communiation to nginx reverse proxy.             |
| Database   | 192.168.1.0/24   | Communication to databases (MariaDB, MongoDB, PostgreSQL). |
| Monitoring | 192.168.2.0/24   | Communication to monitoring utilities (InfluxDB).          |
|            |                  |                                                            |
| Main       | 192.168.100.0/24 | Network for the Main Stack                                 |

```bash
# create main stack
name='main'
mkdir -p "/home/admin/{services,images}/${name}/"
sudo mkdir -p "/srv/${name}/"
sudo docker network create --subnet 192.168.100.0/24 ${name}

# create helper networks (we will need them in the next chapter)
sudo docker network create --subnet 192.168.0.0/24 proxy
sudo docker network create --subnet 192.168.1.0/24 database
sudo docker network create --subnet 192.168.2.0/24 monitoring
```

Lastly we are going to create a `docker-compose.yml` which we will use to define our networks.

```yaml
version: "3"
services: ...

networks:
  default:
    external:
      name: main
  proxy:
    external:
      name: proxy
  database:
    external:
      name: database
  monitoring:
    external:
      name: monitoring
```

The network created for a particular stack will be called `default` in the matching `docker-compose.yml`.
This will help us, because if we do not specify a network in the service sections of the `docker-compose.yml`, these services will automatically connectto network `defalut`.
