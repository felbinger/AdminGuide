We will group the services in different "stacks" to manage them, this way we can change specific things without taking all services offline. Furthermore, we will use one docker network per stack to ensure, that each container is only able to communicate with other containers which it really needs.

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
Helper networks for specific communication (e.g. to the reverse proxy, the databases or the monitoring) start at `192.168.0.0/24`. Stack networks (one network for each stack) start at `192.168.100.0/24`.

!!! note ""
    Note that a network with the submask 255.255.255.0 (cidr notation is 24) can only contain 254 hosts.
    You have to adjust your network size to your needs.

    Remember the formular: $2^{32-x}-2$ where $x$ is your submask in cidr notation  
    (e.g. with $24$: $2^{32−24}−2=254$; or with $20$: $2^{32−20}−2=4094$ usable adresses)

| Name       | Subnet           | Usage                                                      |
| :--------- | :--------------- | :--------------------------------------------------------- |
| Proxy      | 192.168.0.0/24   | Container communication to nginx reverse proxy.            |
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

You can create as many stacks, as you need. The main stack contains the services that are relevant for the majority of the services (e.g. reverse proxy, static webserver for the reverse proxy, databases, admin panels (because they are related to the databases), monitoring). All other services will be outsourced to another stack. The following list containers just a few ideas, how you could name them:

* games: all game servers  
(e.g. Minecraft, Arma 3)

* storage: applications that store your data  
(e.g. NextCloud, Syncthing, ...)

* comms (short form of communication): things to communicate  
(e.g. TeamSpeak, Sinusbot, Telegram Bots, Discord Bots)

* jitsi: another video conference system (simply use [their configuration on github](https://github.com/jitsi/docker-jitsi-meet))

Lastly we are going to create a `docker-compose.yml` which we will use to define our networks.

```yaml
version: "3"
services: 
  ...     # you need to add your services right here...

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
This will help us, because if we do not specify a network in the service sections of the `docker-compose.yml`, these services will automatically connect network `default`.


<details>
  <summary>Parts of the PostInstall script covered in this chapter</summary>

```bash
#!/bin/bash

## CONFIGURATION ###
ADM_NAME='admin'
ADM_GID=997
ADM_HOME='/home/admin'
ADM_USERS=('user')

declare -A STACKS=(\
  ["main"]="192.168.100.0/24"
)

declare -A HELPER=(\
  ["proxy"]="192.168.0.0/24" \
  ["database"]="192.168.1.0/24" \
  ["monitoring"]="192.168.2.0/24"
)
### END of CONFIGURATION ###

function docker_network_create() {
  name=${1}
  subnet=${2}
  docker network inspect ${name} >/dev/null 2>&1 || \
  docker network create --subnet ${subnet} ${name}
}

function create_compose() {
  compose=${1}
  touch ${compose}
  echo -e "version: '3.8'\n" >${compose}

  # define services
  echo -e "services:\n" >>${compose}
  if [[ ${#SERVICES} == 0 ]]; then
    echo -e "  test:" >>${compose}
    echo -e "    image: hello-world\n" >>${compose}
  fi

  echo -e "\n" >>${compose}

  # define networks
  echo -e "networks:" >>${compose}

  # define stack network
  echo -e "  default:" >>${compose}
  echo -e "    external:" >>${compose}
  echo -e "      name: ${name}" >>${compose}

  # define helper networks
  for helper_name in ${!HELPER[@]}; do
    echo -e "  ${helper_name}:" >>${compose}
    echo -e "    external:" >>${compose}
    echo -e "      name: ${helper_name}" >>${compose}
  done
}

# remove trailing slash from ADM_HOME
[[ "${ADM_HOME}" == */ ]] && ADM_HOME="${ADM_HOME::-1}"

# create admin group, add members to group and set permissions
groupadd -g ${ADM_GID} ${ADM_NAME}
mkdir ${ADM_HOME}
chown -R root:${ADM_NAME} ${ADM_HOME}
chmod -R 775 ${ADM_HOME}
for user in ${ADM_USERS}; do
  adduser ${user} ${ADM_NAME}
done

# create helper networks
for name in ${!HELPER[@]}; do
  subnet=${HELPER[${name}]}
  docker_network_create ${name} ${subnet}
done

# create stack logic
mkdir -p ${ADM_HOME}/{services,images,tools,docs}/
for name in ${!STACKS[@]}; do
  subnet=${STACKS[${name}]}
  mkdir -p ${ADM_HOME}/{services,images}/${name}/
  mkdir -p "/srv/${name}/"

  # create stack network
  docker_network_create ${name} ${subnet}

  # create docker-compose.yml
  compose="${ADM_HOME}/services/${name}/docker-compose.yml"
  create_compose ${compose}
done
```

</details>
