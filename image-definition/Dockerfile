FROM mikefarah/yq:4.44.2 as yq
FROM cloudflare/cloudflared:2024.6.1 as cloudflared-binary

FROM alpine:3.20

COPY --from=cloudflared-binary /usr/local/bin/cloudflared /usr/local/bin/

COPY --from=yq /usr/bin/yq /usr/bin/yq

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
