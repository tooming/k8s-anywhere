#!/usr/bin/env bash
# Stable front door for the blue/green DR drill: an nginx reverse proxy on host
# port :8000 that forwards to whichever cluster's Traefik load balancer is "active".
# Cutover = rewrite the upstream + `nginx -s reload`, which is graceful (the master
# keeps the listening socket and drains old workers) -> zero dropped connections.
# It runs on its OWN port, so blue's own :8080 is never touched. The availability
# probe targets :8000 with Host: argocd.127.0.0.1.nip.io (the canary).
#
# Also proxies HTTPS on host :8443 (ADR-0028 follow-up), as a plain TCP passthrough
# to the upstream's :443 — TLS terminates inside Traefik (cert-manager's
# wildcard Certificate), not here, so this stays a second listener alongside the HTTP
# one rather than a second termination point. Same cutover story as :8000: `point`
# rewrites both the http proxy_pass and the stream passthrough in one `nginx -s reload`.
#
# The passthrough needs nginx's stream module, which the official nginx:alpine image
# does NOT ship by default (verified against the image's own Dockerfile — its
# `nginxPackages` list installs xslt/geoip/image-filter/njs/acme but not
# nginx-module-stream). install_stream_module() adds it via `apk add` the first time
# the container is configured (cheap/no-op on every later call — apk only hits the
# network when the module .so isn't already present) and load_module is only emitted
# if that succeeds, so a container with no internet reachability degrades gracefully:
# :8000 keeps working exactly as before, :8443 just doesn't come up.
#
# See docs/DR.md and `make dr-bluegreen`.
#
# Usage:
#   bluegreen-frontdoor.sh up <docker-network> <serverlb-host>   create/point on :8000/:8443
#   bluegreen-frontdoor.sh connect <docker-network>              attach to another net
#   bluegreen-frontdoor.sh point <serverlb-host>                 swap upstream + reload
#   bluegreen-frontdoor.sh target                                print current upstream
#   bluegreen-frontdoor.sh down                                  remove the container
set -euo pipefail

NAME="${FRONTDOOR_NAME:-lab-frontdoor}"
PORT="${FRONTDOOR_PORT:-8000}"
HTTPS_PORT="${FRONTDOOR_HTTPS_PORT:-8443}"
IMG="${FRONTDOOR_IMAGE:-nginx:alpine}"
STREAM_MODULE=/usr/lib/nginx/modules/ngx_stream_module.so

install_stream_module() { # sets HAVE_STREAM=1 if the stream module is usable
  if docker exec "$NAME" test -f "$STREAM_MODULE" 2>/dev/null; then
    HAVE_STREAM=1
  elif docker exec "$NAME" apk add --no-cache nginx-module-stream >/dev/null 2>&1; then
    HAVE_STREAM=1
  else
    echo "[frontdoor] warning: nginx-module-stream unavailable — :$HTTPS_PORT HTTPS passthrough disabled" >&2
    HAVE_STREAM=0
  fi
}

gen_conf() { # $1 = upstream serverlb host; writes nginx.conf to stdout
  [ "${HAVE_STREAM:-0}" = "1" ] && echo "load_module $STREAM_MODULE;"
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
  if [ "${HAVE_STREAM:-0}" = "1" ]; then
    cat <<EOF
stream {
  server {
    listen $HTTPS_PORT;
    # TCP passthrough — Traefik terminates TLS, not us.
    proxy_pass $1:443;
    proxy_connect_timeout 2s;
  }
}
EOF
  fi
}

apply_conf() { # $1 = upstream host; cp config into the container + apply it
  local up="$1" tmp
  install_stream_module
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

main() {
  case "${1:-}" in
    up)
      NET="${2:?network}"; UP="${3:?serverlb host}"
      # A leftover container from an earlier drill may be stopped/exited (and still
      # attached to a now-gone green network). docker exec into it fails and apply_conf
      # then misreports "bad nginx config" — so drop a non-running one and recreate fresh.
      # Also drop (and recreate) a container that predates the :8443 HTTPS passthrough
      # port — docker can't add a published port to an already-running container.
      if docker inspect "$NAME" >/dev/null 2>&1; then
        running="$(docker inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null)"
        if [ "$running" != "true" ] || ! docker port "$NAME" "$HTTPS_PORT/tcp" >/dev/null 2>&1; then
          docker rm -f "$NAME" >/dev/null 2>&1 || true
        fi
      fi
      if ! docker inspect "$NAME" >/dev/null 2>&1; then
        docker run -d --name "$NAME" --network "$NET" -p "$PORT:80" -p "$HTTPS_PORT:$HTTPS_PORT" --restart unless-stopped "$IMG" >/dev/null
        # wait for nginx to be up before reconfiguring
        for _ in $(seq 1 20); do docker exec "$NAME" nginx -t >/dev/null 2>&1 && break; sleep 0.5; done
      else
        docker network connect "$NET" "$NAME" 2>/dev/null || true
      fi
      apply_conf "$UP"
      echo "[frontdoor] up on :$PORT and :$HTTPS_PORT -> $UP"
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
}

# Guarded like bluegreen-probe.sh's probe_loop: sourcing this file (bats coverage
# for gen_conf/install_stream_module) must not also dispatch a docker command.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
