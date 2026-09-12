# Fault-injection drill against the Traefik pod (`kube-system`)

Same Q12 gap-narrowing found live 2026-09-12, this item covers Traefik
specifically — the third and last of three follow-ups to `dr-chaos-argocd`
(2026-09-11) and `dr-chaos-cert-manager` (2026-09-12); `dr-chaos-lab-demo`
remains as a separate ROADMAP item.

**Scope:** added `scripts/dr-chaos-traefik.sh` mirroring
`scripts/dr-chaos-argocd.sh`'s exact shape (same `confirm_or_abort`/
`DR_ASSUME_YES` gate, same `retry`/`fail` helpers, same
`lib/kctx.sh`/`lib/colors.sh`/`lib/confirm.sh` sourcing): kills the live
Traefik pod in the `kube-system` namespace (selector
`app.kubernetes.io/name=traefik` — already a real, live selector this
repo's own `gitops/argocd/networkpolicy/allow-argocd-server-from-gateway.yaml`
uses today to reach the same pod, confirmed directly, not a new
assumption), then polls for a new Ready pod (different UID) and, as the
recovery predicate, that the lab's own HTTP front door answers again —
reusing `http://argocd.127.0.0.1.nip.io:8080/healthz`, the identical URL
`lab-health-check.sh`'s own `UI_PROBES` already probes, rather than
inventing a second endpoint.

Also added: a `make dr-chaos-traefik` target under the Makefile's
"Disaster recovery" section; guard-only bats coverage in
`tests/dr-guards.bats` (unknown-usage/no-confirmation-refusal paths only,
same non-destructive pattern already used for the two prior `dr-chaos-*.sh`
scripts — never actually invoking a live cluster from `make ci`); a
`docs/DR.md` section documenting it, including an honest "Honest scope"
note that killing the lab's only ingress path briefly breaks every other
always-on UI too (this drill measures how fast that self-heals, not
whether it happens — ADR-0005's single-host SPOF is expected, not
disproven); and an update to `docs/dora-audit-readiness.md`'s
Q12 **Answer**/**Evidence**/**Gap** fields reflecting three drills now
exist, naming `lab-demo` as the one remaining component.

`make ci` passes (all bats/lint/validate/drift checks green; the new
script requires a live cluster and is never invoked from CI, same as
every other `dr-*.sh` script). Requires a live cluster; verified locally
(no cluster available in this remote executor session) — same honest
limitation the two prior `dr-chaos-*.sh` scripts' own `docs/done/` entries
recorded, not overclaimed here either. Unlike `dr-chaos-cert-manager.sh`'s
selector, this script's `app.kubernetes.io/name=traefik` selector is
already confirmed live elsewhere in this repo's own manifests, so it does
not carry the same "NEEDS LIVE VERIFICATION" caveat.

## PR

https://github.com/tooming/k8s-anywhere/pull/1577
