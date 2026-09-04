# Gateway HTTPS listener + wildcard Certificate + frontdoor :8443 port mapping

Follow-up to `docs/done/2026-07-16-cert-manager-engine.md`, picked up per direct user
instruction ("yes, pick that up next") right after that PR merged. Closes the item
ADR-0028 §"Scope & exceptions" deliberately deferred out of the engine PR.

## What shipped

**`gitops/network/gateway.yaml`**: added an `https`/443 listener to the shared `Gateway`
alongside (never replacing) the existing `http`/80 one. `tls.mode: Terminate`,
`certificateRefs` pointing at the wildcard Certificate's Secret, `allowedRoutes.namespaces.from: All`
— same shape as the http listener. Every existing HTTPRoute (none declare a
`sectionName`) attaches to both listeners automatically, so every current HTTP URL keeps
working unchanged and becomes reachable over HTTPS too, no per-route change needed.

**`gitops/network/certificates/wildcard-certificate.yaml`** (new): a `Certificate` for
`*.127.0.0.1.nip.io` + `127.0.0.1.nip.io`, issued by `k8s-lab-ca` (the `ca`-type
ClusterIssuer the engine PR's root-CA chain already produced), living in `lab-gateway` —
same namespace as the Gateway, so its Secret needs no `ReferenceGrant`. New auto-synced
`gitops/platform/lab-gateway-certificate.yaml` Application at sync-wave 6, one after
`cert-manager-root-ca` (wave 5) whose ClusterIssuer it references. Until that Secret
lands, the HTTPS listener simply stays not-Programmed and self-heals once it appears —
the same eventual-consistency pattern the root-CA chain itself already relies on.

**`scripts/bluegreen-frontdoor.sh`**: added a `:8443` → upstream `:443` TCP passthrough
alongside the existing `:8000` HTTP `proxy_pass`. TLS terminates inside Envoy at the
Gateway, not at the front door, so this is a second listener, not a second termination
point — same cutover story as `:8000` (`point` rewrites both in one `nginx -s reload`).

Verified against the official `nginx:alpine` image's own Dockerfile (fetched from
`nginxinc/docker-nginx`) before writing any config: its `nginxPackages` list installs
xslt/geoip/image-filter/njs/acme but **not** `nginx-module-stream` — the stream module
isn't in the base image by default. `install_stream_module()` adds it via
`apk add --no-cache nginx-module-stream` the first time the container is configured
(checks for the module `.so` first, so it's a no-op — no network call — on every later
`up`/`point`), and `load_module` is only emitted into the generated `nginx.conf` if that
succeeds. A container with no internet reachability degrades gracefully: `:8000` keeps
working exactly as before, `:8443` just doesn't come up.

`up` now also publishes `-p $HTTPS_PORT:$HTTPS_PORT` (new `FRONTDOOR_HTTPS_PORT`, default
`8443` — matches the k3d `https_port` Terraform variable's existing host-port
convention) and recreates a leftover container that predates this change (detected via
`docker port … 8443/tcp`), since Docker can't add a published port to an already-running
container.

Refactored the script's bottom dispatch into a `main()` function guarded by
`if [ "${BASH_SOURCE[0]}" = "${0}" ]` — the same pattern `bluegreen-probe.sh` already
uses — so the file can be sourced for unit testing `gen_conf`/`install_stream_module`
without also executing a real `docker` command.

## Docs

`CHARTER.md`'s "TLS certificate lifecycle" target entry flipped from "(planned)" to
built. `docs/dependency-tree.md`: new wave-6 table row, a new "Front door :8443" traffic
row, and the cert-manager component paragraph rewritten from "purely additive, nothing
references the issuer chain yet" to describe the live HTTPS path. `README.md`'s
"TLS / certificates" stack-table row extended. `ROADMAP.md`: the engine item flipped to
`[x]`, and this follow-up added as its own checked-off item in the same PR (rule #7).

## Bats coverage

New `tests/frontdoor-https.bats` (16 cases): sourcing safety, `gen_conf`'s HTTP path is
byte-for-byte unaffected when `HAVE_STREAM=0`, the stream block's shape when
`HAVE_STREAM=1` (loads the module, listens on `HTTPS_PORT`, passes through raw TCP —
not `http://` — to `<upstream>:443`), `FRONTDOOR_HTTPS_PORT` override,
`install_stream_module`'s local-check-before-network-call order and graceful-failure
path, the `up` case's port publish + stale-container recreate logic. Extended
`tests/cert-manager.bats` with 10 new cases for the Gateway listener shape, the wildcard
Certificate's namespace/DNS names/issuerRef, and the new Application's wave/source/sync
policy — and updated the engine PR's "not yet referenced outside gitops/cert-manager/"
guard test to allow this follow-up's two deliberate new references instead of weakening
or deleting it.

## Verification

Full local `make ci` green (see PR CI status). `shellcheck`/`yamllint` clean on both
changed scripts. Manually sourced `bluegreen-frontdoor.sh` and called `gen_conf` with
both `HAVE_STREAM=0` and `HAVE_STREAM=1` to confirm the exact nginx config text before
writing the bats assertions against it — this sandbox has no docker daemon, so live
container/TLS-passthrough behavior could not be exercised end-to-end; the module-install
claim is verified against the image's real Dockerfile (ADR-0004's spirit extended to
tooling claims, not just dashboard content), not assumed.

## PR

https://github.com/tooming/k8s-anywhere/pull/440
