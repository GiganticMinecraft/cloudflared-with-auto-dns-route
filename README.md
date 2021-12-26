# `cloudflared-with-auto-dns-route`

A variant of [cloudflared](https://github.com/cloudflare/cloudflared) image that configures dns route according to the provided `tunnel-config.yml`.

## Usage

Replace `<mount-base>` with your preffered path, then write

`/<mount-base>/tunnel-config.yml`:

```YAML
ingress:
  - hostname: host1.example.com
    service: http://local-service-1:8080
  - hostname: host2.example.com
    service: http://local-service-2:8081
  - service: http_status:404
```

where `local-service-1` and `local-service2` are serving some HTTP contents, and 

`docker-compose.yml`:

```YAML
volumes:
  cloudflared-home:

services:
  cloudflared:
    image: "ghcr.io/giganticminecraft/cloudflared-with-auto-dns-route"
    volumes:
      - cloudflared-home:/root
      - /<mount-base>/tunnel-config.yml:/image/tunnel-config.yml
```

Upon `docker compose up`, `cloudflared` container should ask you to login to Cloudflare.
