# Contribution

Feel free to open issues / pull requests. Please validate that your changes work as intented.
You can start the mkdocs development server by running `mkdocs serve`.

## Contribution Guidelines
- Web services are exposed to `[::1]:8000`
- Secret environment variables are in an env_file
  (and not in the `docker-compose.yml` itself, to prevent leaks)
  with the following format:
  ```shell
  # .servicename.env
  KEY=value
  ```
- Environment variables should be in form of a YAML array, not an object:
  ```yaml
  environment:
    - "KEY=value"
  ```
  instead of
  ```yaml
  # WRONG - please don't do this
  environemnt:
    KEY: value
  # WRONG
  ```
- If possible the service should use either mariadb or postgresql.
  If it makes sense, other databases (e.g. sqlite) are also quiet fine.
- YAML arrays should be quoted, regardless which data is stored:
  ```yaml
  volumes:
    - "/srv/service_name/data:/data"
  ports:
    - "[::1]:8000:1234"
  networks:
    - "default"
    - "database"
  ```
- All domain examples should end in `domain.de`
