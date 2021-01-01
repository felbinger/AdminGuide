#!/bin/bash

set -x

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

function install_docker_compose() {
  curl -L "https://github.com/docker/compose/releases/download/latest/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
}

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

# require root privileges
if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

# install docker if not already installed
if [[ -z $(which docker) ]]; then
  if [[ -z $(which docker) ]]; then
    apt-get install curl
  fi
  curl https://get.docker.com | bash
fi

# install docker-compose if not already installed
if [[ -z $(which docker-compose) ]]; then
  install_docker_compose
fi

# remove trailing slash from ADM_HOME
[[ "${ADM_HOME}" == */ ]] && ADM_HOME="${ADM_HOME::-1}"

# create admin group, add members to group and set permissions
groupadd -g ${ADM_GID} ${ADM_NAME}
mkdir ${ADM_HOME}
chown -R root:${ADM_NAME} ${ADM_HOME}
chmod -R 775 ${ADM_HOME}
for user in ${ADM_USERS}; do
  adduser ${user}
  adduser ${user} ${ADM_NAME}
  echo -e '\nalias dc="sudo docker-compose "\n' | tee -a /home/${user}/.bashrc > /dev/null
  echo -e '\nalias ctop="sudo ctop"\n' | tee -a /home/${user}/.bashrc > /dev/null
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

# install ctop
if [[ -z $(which wget) ]]; then
  apt-get install -y wget
fi
wget https://github.com/bcicen/ctop/releases/download/v0.7.3/ctop-0.7.3-linux-amd64 -O /usr/local/bin/ctop
chmod +x /usr/local/bin/ctop

# add tools
if [[ -z $(which wget) ]]; then
  apt-get install -y wget
fi
wget https://github.com/felbinger/DNV/releases/download/v0.1/dnv -O /usr/local/bin/dnv
chmod +x /usr/local/bin/dnv
