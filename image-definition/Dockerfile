FROM mikefarah/yq:4.40.5 as yq
FROM cloudflare/cloudflared:2023.10.0 as cloudflared-binary

FROM alpine:3.19

COPY --from=cloudflared-binary /usr/local/bin/cloudflared /usr/local/bin/

COPY --from=yq /usr/bin/yq /usr/bin/yq

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
