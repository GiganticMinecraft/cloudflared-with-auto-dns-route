FROM mikefarah/yq:4.45.1 as yq
FROM cloudflare/cloudflared:2025.1.0 as cloudflared-binary

FROM alpine:3.21

COPY --from=cloudflared-binary /usr/local/bin/cloudflared /usr/local/bin/

COPY --from=yq /usr/bin/yq /usr/bin/yq

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
