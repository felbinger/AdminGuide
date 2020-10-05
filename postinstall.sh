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

SERVICES=('nginx-proxy' 'mariadb')
### END of CONFIGURATION ###

function install_docker {
  apt-get remove -y --purge docker docker-engine docker.io containerd runc
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl \
    gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
}

function install_docker_compose {
  curl -L "https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
}

function install_python3.8 {
  echo "\n# python3\ndeb [arch=amd64] http://deb.debian.org/debian/ testing main" | tee -a /etc/apt/sources.list
  echo 'APT::Default-Release "stable";' | tee /etc/apt/apt.conf.d/99defaultrelease
  apt-get update
  apt-get install -y python3.8 python3-pip
}

function install_pybackup {
  install_python3.8
  apt-get install -y git jq
  git clone https://github.com/felbinger/pybackup /root/pybackup
  python3 -m pip install -r /root/pybackup/requirements.txt
  # adjust config
  conf='/root/pybackup/.config.json'
  echo $(jq '.backup_dir = "/home/backups/"' < $conf) > $conf
  echo $(jq ".files.path = [\"/srv/\",\"$ADM_HOME\",\"/root\"]" < $conf) > $conf
done
}

function docker_network_create {
  name=${1}
  subnet=${2}
  docker network inspect ${name} >/dev/null 2>&1 || \
    docker network create --subnet ${subnet} ${name}
}


function create_compose {
  compose=${1}
  touch ${compose}
  echo -e "version: '3.8'\n" > ${compose}

  # define services
  echo -e "services:\n" >> ${compose}
  if [[ ${#SERVICES} == 0 ]]; then
    echo -e "  test:" >> ${compose}
    echo -e "    image: hello-world\n" >> ${compose}
  fi

  # add services
  for service in ${SERVICES[@]}; do
    cat "postinstall-services/${service}.yml" >> ${compose}
  done

  echo -e "\n" >> ${compose}

  # define networks
  echo -e "networks:" >> ${compose}

  # define stack network
  echo -e "  default:" >> ${compose}
  echo -e "    external:" >> ${compose}
  echo -e "      name: ${name}" >> ${compose}

  # define helper networks
  for helper_name in ${!HELPER[@]}; do
    echo -e "  ${helper_name}:" >> ${compose}
    echo -e "    external:" >> ${compose}
    echo -e "      name: ${helper_name}" >> ${compose}
  done
}

# require root privileges
if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

# install docker if not already installed
if [[ -z $(which docker) ]]; then
  install_docker
fi

# install docker-compose if not already installed
if [[ -z $(which docker-compose) ]]; then
  install_docker_compose
fi

# remove trailing slash from ADM_HOME
[[ "${ADM_HOME}" == */ ]] && ADM_HOME="${ADM_HOME: : -1}"

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

# install pybackup
install_pybackup

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
wget https://raw.githubusercontent.com/felbinger/scripts/master/docker-networks.py -O /home/admin/tools/networks.py
chmod +x /home/admin/tools/networks.py
