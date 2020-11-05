!!! note "Old Docker Versions"
    > [Older versions of the Docker binary were called docker or docker-engine or docker-io](https://stackoverflow.com/a/45023650)

    If you already installed this version you can uninstall it via:
    ```bash
    sudo apt-get remove docker docker-engine docker.io containerd runc
    ```

Docker it self already provide a very good script:

```bash
curl -fsSL https://get.docker.com | sudo bash
```

Finally, you need to install Docker Compose:

```bash
sudo curl -L -o /usr/local/bin/docker-compose \
  "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
sudo chmod +x /usr/local/bin/docker-compose
```

Instelt of typing `sudo docker-compose up -d` all the time you can use this alias and type `dc up -d`:

```bash
echo 'alias dc="sudo docker-compose "' >> ~/.bashrc
```
