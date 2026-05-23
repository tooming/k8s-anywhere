#!/usr/bin/env bash
# Stable front door for the blue/green DR drill: an nginx reverse proxy on host
# port :8000 that forwards to whichever cluster's Envoy load balancer is "active".
# Cutover = rewrite the upstream + `nginx -s reload`, which is graceful (the master
# keeps the listening socket and drains old workers) -> zero dropped connections.
# It runs on its OWN port, so blue's own :8080 is never touched. The availability
# probe targets :8000 with Host: argocd.127.0.0.1.nip.io (the canary).
# See docs/DR.md and `make dr-bluegreen`.
#
# Usage:
#   bluegreen-frontdoor.sh up <docker-network> <serverlb-host>   create/point on :8000
#   bluegreen-frontdoor.sh connect <docker-network>              attach to another net
#   bluegreen-frontdoor.sh point <serverlb-host>                 swap upstream + reload
#   bluegreen-frontdoor.sh target                                print current upstream
#   bluegreen-frontdoor.sh down                                  remove the container
set -euo pipefail

NAME="${FRONTDOOR_NAME:-lab-frontdoor}"
PORT="${FRONTDOOR_PORT:-8000}"
IMG="${FRONTDOOR_IMAGE:-nginx:alpine}"

gen_conf() { # $1 = upstream serverlb host; writes nginx.conf to stdout
  cat <<EOF
worker_processes 1;
events { worker_connections 1024; }
http {
  access_log off;
  server {
    listen 80;
    # canary/UI traffic: preserve Host so the gateway routes by hostname
    location / {
      proxy_pass http://$1:80;
      proxy_set_header Host \$host;
      proxy_set_header X-Forwarded-For \$remote_addr;
      proxy_connect_timeout 2s;
      proxy_next_upstream error timeout http_502 http_503 http_504;
    }
    location = /_frontdoor_health { return 200 "frontdoor ok\n"; }
  }
}
EOF
}

apply_conf() { # $1 = upstream host; cp config into the container + apply it
  local up="$1" tmp
  tmp="$(mktemp)"; gen_conf "$up" >"$tmp"
  docker cp "$tmp" "$NAME:/etc/nginx/nginx.conf"
  rm -f "$tmp"
  docker exec "$NAME" nginx -t >/dev/null 2>&1 || { echo "[frontdoor] bad nginx config" >&2; return 1; }
  # Graceful hot-reload when the master is already running (its pid file is
  # populated) — no listener gap, in-flight requests finish. On a just-created
  # container the master may not have written /run/nginx.pid yet, so `nginx -s
  # reload` would fail ("invalid PID number"); there's no traffic yet, so just
  # restart the container instead.
  if docker exec "$NAME" sh -c 'test -s /run/nginx.pid' 2>/dev/null; then
    docker exec "$NAME" nginx -s reload
  else
    docker restart "$NAME" >/dev/null
  fi
}

case "${1:-}" in
  up)
    NET="${2:?network}"; UP="${3:?serverlb host}"
    if ! docker inspect "$NAME" >/dev/null 2>&1; then
      docker run -d --name "$NAME" --network "$NET" -p "$PORT:80" --restart unless-stopped "$IMG" >/dev/null
      # wait for nginx to be up before reconfiguring
      for _ in $(seq 1 20); do docker exec "$NAME" nginx -t >/dev/null 2>&1 && break; sleep 0.5; done
    else
      docker network connect "$NET" "$NAME" 2>/dev/null || true
    fi
    apply_conf "$UP"
    echo "[frontdoor] up on :$PORT -> $UP"
    ;;
  connect)
    NET="${2:?network}"; docker network connect "$NET" "$NAME" 2>/dev/null || true
    echo "[frontdoor] connected to $NET"
    ;;
  disconnect)
    NET="${2:?network}"; docker network disconnect "$NET" "$NAME" 2>/dev/null || true
    echo "[frontdoor] disconnected from $NET"
    ;;
  point)
    UP="${2:?serverlb host}"; apply_conf "$UP"; echo "[frontdoor] now -> $UP"
    ;;
  target)
    docker exec "$NAME" sh -c 'grep -oE "proxy_pass http://[^:]+" /etc/nginx/nginx.conf | head -1' 2>/dev/null || echo "(not running)"
    ;;
  down)
    docker rm -f "$NAME" >/dev/null 2>&1 || true; echo "[frontdoor] removed"
    ;;
  *) echo "usage: $0 {up <net> <host>|connect <net>|disconnect <net>|point <host>|target|down}" >&2; exit 2;;
esac
