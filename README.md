# Admin Guide
You can find this repository here: [https://adminguide.pages.dev](https://adminguide.pages.dev).

## Contribute
Feel free to open issues / pull requests.
<br>
<br>
Please validate that your changes work as intented!
<br>
You can start the mkdocs development server by running:
```bash
sudo ./serve.sh
# or
sudo sh ./serve.sh
```
The http server is then listening on port 8000.
<br>
<br>
**Please review every script from the Internet before executing it!**

### Contribution Guidelines
* Web Services are exposed to `[::1]:8000`
* Environment Variables are in an env_file (and not in the `docker-compose.yml`) with the following format:
  ```shell
  # .servicename.env
  KEY=value
  ```
* If possible the service should use either mariadb or postgresql.
  If it makes sense, other databases (e.g. sqlite) are also quiet fine.
* YAML arrays should be quoted, regardless which data is stored:
  ```yaml
  volumes:
    - "/srv/service_name/data:/data"
  ports:
    - "[::1]:8000:1234"
  ```