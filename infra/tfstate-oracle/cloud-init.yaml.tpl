#cloud-config
# Bootstraps the standalone Garage instance backing the oracle Terraform backend's
# state. Template — scripts/tfstate-oracle-bootstrap.sh substitutes __GARAGE_TOML_B64__
# with the base64-encoded, secret-filled infra/tfstate-oracle/garage.toml.tpl before
# this ships as instance user-data.
write_files:
  - path: /etc/garage.toml
    encoding: b64
    content: __GARAGE_TOML_B64__
    permissions: '0600'

runcmd:
  - curl -fsSL https://get.docker.com | sh -
  - systemctl enable --now docker
  - usermod -aG docker ubuntu
  - >-
    docker run -d --name tfstate-garage --restart unless-stopped
    -v /etc/garage.toml:/etc/garage.toml:ro
    -v garage_data:/var/lib/garage
    -p 3900:3900 -p 3901:3901 -p 3903:3903
    dxflrs/garage:v2.3.0
  - sh -c 'i=0; until docker exec tfstate-garage /garage status >/dev/null 2>&1 || [ "$i" -ge 150 ]; do sleep 2; i=$((i + 1)); done; docker exec tfstate-garage /garage status >/dev/null 2>&1 || { echo "tfstate-garage did not report status after 300s -- container/config likely broken" >&2; exit 1; }'
