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

function create_compose() {
  cp resources/docker-compose.template.yml ${1}
  # stack network
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

echo ">>> Installing Software"
apt-get update
apt-get install sudo curl wget borgbackup

# install docker if not already installed
if [[ -z $(which docker) ]]; then
  curl https://get.docker.com | bash
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
mkdir ${ADM_HOME}
chown -R root:${ADM_NAME} ${ADM_HOME}
chmod -R 775 ${ADM_HOME}
for user in ${ADM_USERS[@]}; do
  # check if user exists
  if [ ! $(sed -n "/^${user}/p" /etc/passwd) ]; then
    /usr/sbin/useradd --create-home --shell=/bin/bash ${user}
  fi
  /usr/sbin/usermod --append --groups=sudo,${ADM_NAME} ${user}

  # add aliases
  echo -e '\nalias dc="sudo docker-compose "' | tee -a /home/${user}/.bashrc > /dev/null
  echo -e 'alias ctop="sudo ctop"\n' | tee -a /home/${user}/.bashrc > /dev/null

  # check if exist
  [ ! -h "/home/{user}/admin" ] && ln -s ${ADM_HOME} /home/${user}/admin
done

echo ">>> Creating Docker Stacks"
# create helper networks
for name in ${!HELPER[@]}; do
  docker network inspect ${name} >/dev/null 2>&1 || docker network create --subnet ${HELPER[${name}]} ${name}
done

# create stack logic
mkdir -p ${ADM_HOME}/{services,images,tools,docs}/
for name in ${!STACKS[@]}; do
  mkdir -p "${ADM_HOME}/{services,images}/${name}/" "/srv/${name}/"

  # create stack network
  docker network inspect ${name} >/dev/null 2>&1 || docker network create --subnet ${STACKS[${name}]} ${name}

  # create docker-compose.yml
  [ ! -f "${ADM_HOME}/services/${name}/docker-compose.yml" ] && create_compose "${ADM_HOME}/services/${name}/docker-compose.yml"
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

wget -q https://raw.githubusercontent.com/felbinger/scripts/master/genpw.sh -O /usr/local/bin/genpw
chmod +x /usr/local/bin/genpw

exit

# untested functions
echo ">>> Setup Backup"
export BORG_PASSPHRASE=$(/usr/local/bin/genpw)
echo "export BORG_PASSPHRASE=${BORG_PASSPHRASE}" > /root/.borg.sh
echo ">>> Borg Passphrase is: ${BORG_PASSPHRASE}"
borg init -e repokey /home/borg
borg key export /home/borg /root/borg-key.txt
echo ">>> Borg Key has been saved to /root/borg-key.txt"
echo ">>> Make sure to save this file to your local machine and delete it afterwards."

# adjust cronjob

echo ">>> Setup Exporter User"
username="exporter"
useradd -s /bin/false -m ${username}
rm /home/${username}/.{bashrc,bash_logout,profile}
cp /etc/ssh/sshd_config{,.bak}

# add exporter user to allow users
sed -i "/AllowUsers/ s/$/ ${username}/" /etc/ssh/sshd_config

# setup sftp jail
cat <<EOF >> /etc/ssh/sshd_config
AuthorizedKeysFile .ssh/authorized_keys /etc/ssh/authorized_keys/%u
Match User ${username}
  X11Forwarding no
  AllowTcpForwarding no
  PermitTTY no
  ForceCommand internal-sftp
  ChrootDirectory /home/${username}/
Match all
EOF
mkdir -p /etc/ssh/authorized_keys/
touch /etc/ssh/authorized_keys/exporter

echo ">>> Add the ssh public keys for the exporter user to /etc/ssh/authorized_keys/exporter"

# copy scripts
cp resources/{,export_}backup.sh /root/
chmod +x /root/backup.sh
chmod +x /root/export_backup.sh

echo ">>> You may want to set a telegram token in /root/.telegram.sh and adjust the chat_id in the scripts."
echo "export TELEGRAM_TOKEN=" > /root/.borg.sh
