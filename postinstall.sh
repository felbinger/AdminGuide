#!/bin/bash

## CONFIGURATION ###
ADM_NAME='admin'
ADM_GID=997
ADM_HOME='/home/admin'
ADM_USERS=('user')

declare -A STACKS=(\
  ["main"]="192.168.100.0/24"
  ["comms"]="192.168.101.0/24"
  ["storage"]="192.168.102.0/24"
)

declare -A HELPER=(\
  ["proxy"]="192.168.0.0/24" \
  ["database"]="192.168.1.0/24" \
  ["monitoring"]="192.168.2.0/24"
)
### END of CONFIGURATION ###

function install_docker_compose() {
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
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
  echo -e "version: '3.9'\n" >${compose}

  # define services
  echo -e "services:" >>${compose}
  echo -e "  test:" >>${compose}
  echo -e "    image: hello-world" >>${compose}

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

if [[ ${RERUN} == 1 ]]; then
  echo "You already ran the script, if you really want to run the script again set 'RERUN=0'. (This might break your system!)"
  exit 1
fi

# add rerun=1 variable to prevent postinstall to be executed multiple times
sed -i '2 i\RERUN=1' ${0}

# print all executed commands
set -x

apt-get update

if [[ -z $(which curl) ]]; then
  apt-get install -y curl
fi

# install docker if not already installed
if [[ -z $(which docker) ]]; then
  curl https://get.docker.com | bash
fi

# install docker-compose if not already installed
if [[ -z $(which docker-compose) ]]; then
  install_docker_compose
fi

# remove trailing slash from ADM_HOME
[[ "${ADM_HOME}" == */ ]] && ADM_HOME="${ADM_HOME::-1}"

# create admin group, add members to group and set permissions
/usr/sbin/groupadd -g ${ADM_GID} ${ADM_NAME}
mkdir ${ADM_HOME}
chown -R root:${ADM_NAME} ${ADM_HOME}
chmod -R 775 ${ADM_HOME}
for user in ${ADM_USERS[@]}; do
  if [ ! $(sed -n "/^${user}/p" /etc/passwd) ]; then
    /usr/sbin/useradd -m --shell=/bin/bash ${user}
  fi
  /usr/sbin/usermod --append --groups=sudo,${ADM_NAME} ${user}

  echo -e '\nalias dc="sudo docker-compose "' | tee -a /home/${user}/.bashrc > /dev/null
  echo -e 'alias ctop="sudo ctop"\n' | tee -a /home/${user}/.bashrc > /dev/null

  # check if exist
  [ ! -h "/home/{user}/admin" ] && ln -s ${ADM_HOME} /home/${user}/admin
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
  if [ ! -f ${compose} ]; then
    create_compose ${compose}
  fi
done

# adjust permissions
chown -R root:admin ${ADM_HOME}
find ${ADM_HOME} -type d -exec chmod 0775 {} \;
find ${ADM_HOME} -type f -exec chmod 0664 {} \;
find ${ADM_HOME}/tools/ -type f -exec chmod 0775 {} \;

# ctop.sh
if [ -z $(which /usr/local/bin/ctop) ]; then
  curl -LJO https://github.com/bcicen/ctop/releases/download/v0.7.5/ctop-0.7.5-linux-amd64
  mv ctop-0.7.5-linux-amd64 /usr/local/bin/ctop
  chmod +x /usr/local/bin/ctop
fi

# docker network viewer
if [ -z $(which /usr/local/bin/dnv) ]; then
  curl -LJO https://github.com/felbinger/DNV/releases/download/v0.1/dnv
  mv dnv /usr/local/bin/dnv
  chmod +x /usr/local/bin/dnv
fi
