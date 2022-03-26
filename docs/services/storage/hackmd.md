# HackMD

```yaml
  hackmd:
    image: hackmdio/hackmd
    restart: always
    ports:
      - "[::1]:8000:3000"
    environment:
      - "CMD_DB_URL=mysql://hackmd:S3cr3T@mariadb/hackmd"
```
