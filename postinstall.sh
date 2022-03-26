#!/bin/bash

## CONFIGURATION ###
ADM_NAME='admin'
ADM_GID=997
ADM_HOME='/home/admin'
ADM_USERS=()
### END of CONFIGURATION ###

# require root privileges
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
fi

echo ">>> Installing Software"
apt-get update
apt-get install sudo curl wget borgbackup

# install docker if not already installed
if [[ -z $(which docker) ]]; then
    curl -fsSL https://get.docker.com | bash
fi

# install docker-compose if not already installed
if [[ -z $(which docker-compose) ]]; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# remove trailing slash from ADM_HOME
[[ "${ADM_HOME}" == */ ]] && ADM_HOME="${ADM_HOME::-1}"

# create admin group, add members to group and set permissions
echo ">>> Creating Admin Setup"
/usr/sbin/groupadd -g ${ADM_GID} ${ADM_NAME}
mkdir -p ${ADM_HOME}
chown -R root:${ADM_NAME} ${ADM_HOME}
chmod -R 775 ${ADM_HOME}
# shellcheck disable=SC2068
# usernames can't have spaces -> can be interpreted as two usernames
for user in ${ADM_USERS[@]}; do
    # check if user exists
    if ! id "${user}"; then
      /usr/sbin/useradd --create-home --shell=/bin/bash "${user}"
    fi
    /usr/sbin/usermod --append --groups=sudo,${ADM_NAME} "${user}"

    # add aliases
    if ! grep 'alias dc' .bashrc; then
        echo -e '\nalias dc="sudo docker-compose "' | tee -a "/home/${user}/.bashrc" > /dev/null
    fi

    # check if exist
    [ ! -h "/home/{user}/admin" ] && ln -s ${ADM_HOME} /home/${user}/admin
done

# adjust permissions
chown -R root:admin ${ADM_HOME}
find ${ADM_HOME} -type d -exec chmod 0775 {} \;
find ${ADM_HOME} -type f -exec chmod 0664 {} \;
find ${ADM_HOME}/tools/ -type f -exec chmod 0775 {} \;

wget -q https://raw.githubusercontent.com/felbinger/scripts/master/genpw.sh -O /usr/local/bin/genpw
chmod +x /usr/local/bin/genpw
