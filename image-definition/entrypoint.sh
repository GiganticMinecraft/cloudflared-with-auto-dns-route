#!/bin/ash
# shellcheck shell=dash
set -e

# based on
# https://github.com/kory33/oracle-cloud-gp-servers/blob/ec7e8fa1c8206cdc9fb60b5ebe39aef1a659ae18/services/cloudflared/entrypoint.sh

TUNNEL_NAME=${TUNNEL_NAME:-cloudflared_tunnel}

# list tunnel information in yaml format.
# A typical output is 
# - id: ********-****-****-****-************
#   name: ********
#   createdat: ****-**-**T**:**:**.******Z
#   deletedat: 0001-01-01T00:00:00Z
#   connections: []
list_tunnel_as_yaml () {
  cloudflared tunnel list --name "$TUNNEL_NAME" --output yaml
}

recreate_tunnel () {
  cloudflared tunnel delete -f "$TUNNEL_NAME" || true
  cloudflared tunnel create "$TUNNEL_NAME"
}

get_available_tunnel_id () {
  list_tunnel_as_yaml | yq eval '.[0].id' -
}

ensure_tunnel_exists_and_we_have_access () {
  # recreate tunnel if we don't have a tunnel or the credential to the tunnel
  if [ "$(get_available_tunnel_id)" = "null" ] ||\
     [ ! -f "/root/.cloudflared/$(get_available_tunnel_id).json" ]; then    
    echo "recreating tunnel..."
    recreate_tunnel
  fi
}

if ! command -v yq > /dev/null 2>&1; then
  echo "yq must be installed to run this initialization script"
  exit 1
fi

input_tunnel_config_path=/etc/cloudflared/tunnel-config.yml
tmp_tunnel_config_path=/tmp/tunnel-config.yml

if [ -f "$tmp_tunnel_config_path" ]; then
  echo "tunnel-config.yml already present at ${tmp_tunnel_config_path}, but this is unexpected."
  echo "Consider mounting your tunnel-config.yml at ${input_tunnel_config_path} instead."
fi

if [ -f "$input_tunnel_config_path" ]; then
  echo "Using tunnel-config.yml provided at ${input_tunnel_config_path}"
  cp "$input_tunnel_config_path" "$tmp_tunnel_config_path"
else
  echo "${input_tunnel_config_path} not found, using a fresh one without any nontrivial routes."
  echo """
ingress:
  - service: http_status:404
""" > "$tmp_tunnel_config_path"
fi

if [ -n "${CLOUDFLARED_HOSTNAME+found}" ] && [ -n "${CLOUDFLARED_SERVICE+found}" ]; then
  yq eval -i \
    '.ingress = [{ "hostname": strenv(CLOUDFLARED_HOSTNAME), "service": strenv(CLOUDFLARED_SERVICE) }] + .ingress' \
    "$tmp_tunnel_config_path"
fi

echo "Tunnel configuration to apply:"
cat "$tmp_tunnel_config_path"

# login if cert.pem not found
if [ -z "${TUNNEL_ORIGIN_CERT}" ]; then TUNNEL_ORIGIN_CERT="$HOME/.cloudflared/cert.pem"; fi
if [ ! -f "${TUNNEL_ORIGIN_CERT}" ]; then
  cloudflared tunnel login
fi

echo "Current tunnel list:"
list_tunnel_as_yaml

ensure_tunnel_exists_and_we_have_access

tunnel_id=$(get_available_tunnel_id)

# re-route all domains in ingress-rules to this tunnel.
echo "Re-routing all domains to the tunnel..."
yq e ".ingress.[] | select(.hostname != null) | .hostname" "$tmp_tunnel_config_path" \
  | xargs -n 1 cloudflared tunnel route dns --overwrite-dns "$tunnel_id"

# start the tunnel
echo "Starting the tunnel"
cloudflared tunnel --config "$tmp_tunnel_config_path" --no-autoupdate run "$tunnel_id"
