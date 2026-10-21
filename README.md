# `cloudflared-with-auto-dns-route`

A variant of [cloudflared](https://github.com/cloudflare/cloudflared) image that configures dns route according to the provided `tunnel-config.yml`.

## Usage

You may use one of the following way to configure DNS routes to your services. You may also specify `CLOUDFLARED_HOSTNAME` / `CLOUDFLARED_SERVICE` **and** mount `tunnel-config.yml`, but in this case the routing specified by environment variables is inserted at the beginning of the `ingress` list.

Whichever option you may choose, `cloudflared` container should ask you to login to Cloudflare upon `docker compose up`.

After the DNS routes are configured, the entrypoint `exec`s `cloudflared tunnel run`, so `cloudflared` runs as PID 1 and handles `SIGTERM` itself: it stops accepting new requests and waits up to `TUNNEL_GRACE_PERIOD` (default `20s`, below Kubernetes' default 30s `terminationGracePeriodSeconds`) for in-flight requests before exiting.

### Mounting `tunnel-config.yml`

Replace `<mount-base>` with your preffered path (either absolute, or relative from workdir of docker compose), then write

`<mount-base>/tunnel-config.yml`:

```YAML
ingress:
  - hostname: host1.example.com
    service: http://local-service-1:8080
  - hostname: host2.example.com
    service: http://local-service-2:8081
  - service: http_status:404
```

where `local-service-1` and `local-service2` are serving some HTTP contents.

`docker-compose.yml`:

Now mount your `tunnel-config.yml` to `/etc/cloudflared/tunnel-config.yml`:

```YAML
volumes:
  cloudflared-home:

services:
  cloudflared:
    image: "ghcr.io/giganticminecraft/cloudflared-with-auto-dns-route"
    volumes:
      - cloudflared-home:/root
      - <mount-base>/tunnel-config.yml:/etc/cloudflared/tunnel-config.yml
    environments:
      TUNNEL_NAME: example-tunnel-1
```

### Using a pair of environment variables

`docker-compose.yml`:

```YAML
volumes:
  cloudflared-home:

services:
  cloudflared:
    image: "ghcr.io/giganticminecraft/cloudflared-with-auto-dns-route"
    environment:
      CLOUDFLARED_HOSTNAME: host1.example.com
      CLOUDFLARED_SERVICE: http://local-service-1:8080
    volumes:
      - cloudflared-home:/root
    environments:
      TUNNEL_NAME: example-tunnel-1
```
