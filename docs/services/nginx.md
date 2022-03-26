# nginx

```yaml
version: '3.9'

services:
  homepage:
    image: nginx
    restart: always
    ports:
      - "[::1]:8000:80" 
    volumes:
      - "/srv/homepage:/usr/share/nginx/html/"
```