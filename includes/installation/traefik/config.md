Nun müssen noch einige Konfigurationen angelegt werden:
```yaml
# /srv/traefik/middlewares.yml 
http:
  middlewares:
    mw_compress:
      compress: true
    mw_hsts:
      headers:
        contentTypeNosniff: true
        browserXssFilter: true
        forceSTSHeader: true
        sslRedirect: true
        stsPreload: true
        stsSeconds: 315360000
        stsIncludeSubdomains: true
        customResponseHeaders:
        X-Forwarded-Proto: https
        X-Frame-Options: sameorigin
```

```yaml
# /srv/traefik/dynamic.yml
tls:
  options:
    default:
      minVersion: VersionTLS12
      sniStrict: true
      cipherSuites:
        # TLS 1.3
        - TLS_AES_256_GCM_SHA384
        - TLS_CHACHA20_POLY1305_SHA256
        - TLS_AES_128_GCM_SHA256
        # TLS 1.2
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
```