FROM mikefarah/yq:4.54.1 AS yq
FROM cloudflare/cloudflared:2026.10.7 AS cloudflared-binary

FROM alpine:3.24

COPY --from=cloudflared-binary /usr/local/bin/cloudflared /usr/local/bin/

COPY --from=yq /usr/bin/yq /usr/bin/yq

COPY ./entrypoint.sh /entrypoint.sh

# cloudflared's env var for `tunnel --grace-period` (upstream default 30s). Kept at or below
# Docker's default stop timeout (10s) and Kubernetes' default terminationGracePeriodSeconds (30s)
# so that in-flight requests are cut by cloudflared itself rather than by SIGKILL.
ENV TUNNEL_GRACE_PERIOD=10s

ENTRYPOINT [ "/entrypoint.sh" ]
