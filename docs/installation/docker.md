!!! note "Old Docker Versions"
    > [Older versions of the Docker binary were called docker or docker-engine or docker-io](https://stackoverflow.com/a/45023650)

    If you already installed this version you can uninstall it via:
    ```bash
    sudo apt-get remove docker docker-engine docker.io containerd runc
    ```

Docker itself already provide a very good script:

```bash
curl -fsSL https://get.docker.com | sudo bash
```

Finally, you need to install Docker Compose:

```bash
sudo curl -L -o /usr/local/bin/docker-compose \
  "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
sudo chmod +x /usr/local/bin/docker-compose
```

Instead of typing `sudo docker-compose up -d` all the time you can use this alias and type `dc up -d`:

```bash
echo 'alias dc="sudo docker-compose "' >> ~/.bashrc
```

<details>
  <summary>Parts of the PostInstall script covered in this chapter</summary>

```bash
#!/bin/bash

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
```

</details>
