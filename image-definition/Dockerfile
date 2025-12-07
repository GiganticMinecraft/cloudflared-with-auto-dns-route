FROM mikefarah/yq:4.49.2 AS yq
FROM cloudflare/cloudflared:2025.11.1 AS cloudflared-binary

FROM alpine:3.23

COPY --from=cloudflared-binary /usr/local/bin/cloudflared /usr/local/bin/

COPY --from=yq /usr/bin/yq /usr/bin/yq

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
