#!/bin/ash
# shellcheck shell=dash
set -e

# based on
# https://github.com/kory33/oracle-cloud-gp-servers/blob/ec7e8fa1c8206cdc9fb60b5ebe39aef1a659ae18/services/cloudflared/entrypoint.sh

tunnel_name=seichi_debug_servers-tunnels

# list tunnel information in yaml format.
# A typical output is 
# - id: ********-****-****-****-************
#   name: ********
#   createdat: ****-**-**T**:**:**.******Z
#   deletedat: 0001-01-01T00:00:00Z
#   connections: []
list_tunnel_as_yaml () {
  cloudflared tunnel list --name $tunnel_name --output yaml
}

recreate_tunnel () {
  cloudflared tunnel delete -f $tunnel_name || true
  cloudflared tunnel create $tunnel_name
}

get_available_tunnel_id () {
  list_tunnel_as_yaml | yq eval '.[0].id' -
}

ensure_tunnel_exists_and_we_have_access () {
  # recreate tunnel if we don't have a tunnel or the credential to the tunnel
  if [ $(get_available_tunnel_id) = "null" ] ||\
     [ ! -f "/root/.cloudflared/$(get_available_tunnel_id).json" ]; then    
    echo "recreating tunnel..."
    recreate_tunnel
  fi
}

if ! command -v yq > /dev/null 2>&1; then
  echo "yq must be installed to run this initialization script"
  exit 1
fi

if [ -f /tmp/tunnel-config.yml ]; then
  echo "tunnel-config.yml already present at /tmp/tunnel-config.yml, but this is unexpected."
  echo "Consider mounting your tunnel-config.yml at /etc/tunnel-config.yml instead."
fi

if [ -f /etc/tunnel-config.yml ]; then
  echo "Using tunnel-config.yml provided at /etc/tunnel-config.yml"
  cp /etc/tunnel-config.yml /tmp/tunnel-config.yml
else
  echo "/etc/tunnel-config.yml not found, using a fresh one without any nontrivial routes."
  echo """
ingress:
  - service: http_status:404
""" > /tmp/tunnel-config.yml
fi

if [ -n "${CLOUDFLARED_HOSTNAME+found}" ] && [ -n "${CLOUDFLARED_SERVICE+found}" ]; then
  yq eval -i \
    '.ingress = [{ "hostname": strenv(CLOUDFLARED_HOSTNAME), "service": strenv(CLOUDFLARED_SERVICE) }] + .ingress' \
    /tmp/tunnel-config.yml
fi

# login if cert.pem not found
if [ ! -f ~/.cloudflared/cert.pem ]; then
  cloudflared tunnel login
fi

echo "Current tunnel list:"
echo $(list_tunnel_as_yaml)

ensure_tunnel_exists_and_we_have_access

tunnel_id=$(get_available_tunnel_id)

# re-route all domains in ingress-rules to this tunnel.
echo "Re-routing all domains to the tunnel..."
yq e ".ingress.[] | select(.hostname != null) | .hostname" /tmp/tunnel-config.yml \
  | xargs -n 1 cloudflared tunnel route dns --overwrite-dns "$tunnel_id"

# start the tunnel
echo "Starting the tunnel"
cloudflared tunnel --config /tmp/tunnel-config.yml --no-autoupdate run "$tunnel_id"
