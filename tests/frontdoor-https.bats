#!/usr/bin/env bats
# Clusterless structural + unit tests for the frontdoor's HTTPS TCP passthrough
# (ADR-0028 follow-up — Gateway HTTPS listener + wildcard Certificate + frontdoor
# :8443 port mapping). No docker daemon required: gen_conf/install_stream_module
# are pure-ish shell functions, sourced with the guard bluegreen-probe.sh already
# established (`if [ "${BASH_SOURCE[0]}" = "${0}" ]`) so sourcing never dispatches
# a real docker command. Covers the nginx config shape, not live TLS passthrough —
# that needs a running docker daemon + cluster (out of scope for clusterless CI).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FRONTDOOR="$REPO/scripts/bluegreen-frontdoor.sh"
  # shellcheck source=/dev/null
  source "$FRONTDOOR"
}

# --- sourcing safety (mirrors bluegreen-probe.bats' guard assumption) --------

@test "bluegreen-frontdoor.sh is safe to source (does not dispatch a docker command)" {
  # If the guard were missing this setup() call itself would already have failed
  # (usage message + exit 2, set -e). Reaching here proves the guard works.
  [ -n "$FRONTDOOR" ]
}

@test "bluegreen-frontdoor.sh guards main() dispatch behind BASH_SOURCE check" {
  run grep -q 'BASH_SOURCE\[0\]' "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

# --- gen_conf: HTTP path is unaffected (additive-safe) -----------------------

@test "gen_conf always emits the http proxy_pass to the upstream on :80" {
  HAVE_STREAM=0
  run gen_conf myupstream
  [[ "$output" == *"proxy_pass http://myupstream:80;"* ]]
}

@test "gen_conf without HAVE_STREAM emits no load_module or stream block" {
  HAVE_STREAM=0
  run gen_conf myupstream
  [[ "$output" != *"load_module"* ]]
  [[ "$output" != *"stream {"* ]]
}

# --- gen_conf: HTTPS passthrough (HAVE_STREAM=1) ------------------------------

@test "gen_conf with HAVE_STREAM=1 loads the stream module" {
  HAVE_STREAM=1
  run gen_conf myupstream
  [[ "$output" == *"load_module $STREAM_MODULE;"* ]]
}

@test "gen_conf with HAVE_STREAM=1 listens on HTTPS_PORT in the stream block" {
  HAVE_STREAM=1
  run gen_conf myupstream
  [[ "$output" == *"listen $HTTPS_PORT;"* ]]
}

@test "gen_conf with HAVE_STREAM=1 passes through TCP to upstream:443 (not http://)" {
  HAVE_STREAM=1
  run gen_conf myupstream
  [[ "$output" == *"proxy_pass myupstream:443;"* ]]
  [[ "$output" != *"proxy_pass http://myupstream:443"* ]]
}

@test "HTTPS_PORT defaults to 8443" {
  [ "$HTTPS_PORT" = "8443" ]
}

@test "FRONTDOOR_HTTPS_PORT overrides the default" {
  run env FRONTDOOR_HTTPS_PORT=9443 bash -c "source '$FRONTDOOR'; echo \$HTTPS_PORT"
  [ "$status" -eq 0 ]
  [ "$output" = "9443" ]
}

# --- install_stream_module: local-check-first, no needless network ----------

@test "install_stream_module checks for the module file before attempting apk add" {
  run grep -q 'test -f "\$STREAM_MODULE"' "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

@test "install_stream_module falls back to apk add nginx-module-stream" {
  run grep -q 'apk add --no-cache nginx-module-stream' "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

@test "install_stream_module degrades HAVE_STREAM to 0 on failure rather than erroring out" {
  run grep -q 'HAVE_STREAM=0' "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

# --- up: publishes the new port + recreates a stale container ----------------

@test "up publishes both PORT and HTTPS_PORT" {
  run grep -q -- '-p "\$PORT:80" -p "\$HTTPS_PORT:\$HTTPS_PORT"' "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

@test "up recreates a leftover container missing the HTTPS_PORT publish" {
  run grep -q 'docker port "\$NAME" "\$HTTPS_PORT/tcp"' "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

# --- apply_conf wires install_stream_module in on every up/point call --------

@test "apply_conf calls install_stream_module before generating the config" {
  run bash -c "awk '/^apply_conf\(\)/,/^}/' '$FRONTDOOR' | grep -q install_stream_module"
  [ "$status" -eq 0 ]
}

# --- frontdoor-ensure.sh surfaces the new HTTPS entry point -------------------

@test "frontdoor-ensure.sh mentions the :8443 HTTPS entry point" {
  run grep -q '8443' "$REPO/scripts/frontdoor-ensure.sh"
  [ "$status" -eq 0 ]
}

# --- local cluster's direct https_port must never collide with the frontdoor's
# canonical :8443 passthrough — both are host-port `docker run` bindings on the
# same machine, so a `make up` with them equal fails with "port is already
# allocated" the moment frontdoor-ensure.sh runs (found the hard way: #440's
# https_port=8443 "matched" the frontdoor default instead of avoiding it). -----

@test "local cluster's https_port terragrunt override is not the frontdoor's default HTTPS_PORT" {
  run grep -E 'https_port[[:space:]]*=[[:space:]]*8443' "$REPO/infra/live/local/cluster/terragrunt.hcl"
  [ "$status" -ne 0 ]
}

@test "k3d-cluster module's https_port default is not the frontdoor's default HTTPS_PORT" {
  run bash -c "awk '/variable \"https_port\"/,/^}/' '$REPO/infra/modules/k3d-cluster/variables.tf' | grep -E 'default[[:space:]]*=[[:space:]]*8443'"
  [ "$status" -ne 0 ]
}
