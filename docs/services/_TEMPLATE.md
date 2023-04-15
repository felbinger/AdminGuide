# Servicename

```yaml
# docker compose file
```

```shell
# env files for secrets
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "..."
    ```