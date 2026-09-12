# Fault-injection drill against the `cert-manager` controller pod

Found live 2026-09-12 (planner gap analysis, re-reading
`docs/dora-audit-readiness.md`'s own Q12 **Gap** field after `dr-chaos-argocd`
shipped): Q12's gap is explicitly described as "narrowed, not closed" —
`dr-chaos-argocd` covers only ArgoCD's application-controller pod; the other
three always-on components (cert-manager, Traefik, `lab-demo`) have no
equivalent drill yet. This item covers cert-manager; Traefik and `lab-demo`
are separate items (kept as three small PRs, not one large one, per
WAYS-OF-WORKING.md §3's size discipline — mirrors `dr-chaos-argocd`'s own
single-component scope).

**Scope:** added `scripts/dr-chaos-cert-manager.sh` mirroring
`scripts/dr-chaos-argocd.sh`'s exact shape (same `confirm_or_abort`/
`DR_ASSUME_YES` gate, same `retry`/`fail` helpers, same
`lib/kctx.sh`/`lib/colors.sh`/`lib/confirm.sh` sourcing): kills the live
cert-manager controller pod in the `cert-manager` namespace (selector
`app.kubernetes.io/name=cert-manager` — the upstream Jetstack chart's own
controller-pod label, distinct from its sibling `cainjector`/`webhook`
pods; **flagged explicitly as NEEDING LIVE VERIFICATION on the next cluster
rebuild** — not asserted as confirmed, ADR-0004, mirroring the identical
caveat this repo's own
`gitops/cert-manager/networkpolicy/allow-cert-manager-webhook-from-apiserver.yaml`
already carries for a label/behavior assumption in the same namespace), then
polls for a new Ready pod (different UID) and, as the recovery predicate,
that the root-CA issuer chain returns to Ready: the `k8s-lab-ca`
`ClusterIssuer` and the `k8s-lab-root-ca` `Certificate`
(`gitops/cert-manager/root-ca/`, confirmed directly against the real
manifests rather than guessed) both report `status.conditions[Ready] ==
True` again — `dr-verify.sh` itself had no existing cert-manager predicate
to reuse (checked directly, none found), so this predicate was authored
fresh from the real root-CA bootstrap chain's actual resource names.

Also added: a `make dr-chaos-cert-manager` target under the Makefile's
"Disaster recovery" section, next to `dr-chaos-argocd`; guard-only bats
coverage in `tests/dr-guards.bats` (unknown-usage/no-confirmation-refusal
paths only, same non-destructive pattern already used for
`dr-chaos-argocd.sh`/`dr-test.sh`/`dr-destroy.sh` — never actually invoking a
live cluster from `make ci`); a `docs/DR.md` section documenting it,
mirroring `dr-chaos-argocd`'s own section shape including its "Honest scope"
paragraph and this drill's own live-verification caveat; and an honest
update to `docs/dora-audit-readiness.md`'s Q12 **Answer**/**Evidence**/**Gap**
fields reflecting two drills now exist (ArgoCD, cert-manager), naming
Traefik and `lab-demo` as the two still-remaining components (both already
tracked as separate ROADMAP items) — and naming the cert-manager drill's own
unverified selector explicitly in the **Gap** field rather than letting
"narrowed the gap" imply the new drill itself is fully trustworthy yet.

`make ci` passes (all bats/lint/validate/drift checks green; the new script
requires a live cluster and is never invoked from CI, same as every other
`dr-*.sh` script). Requires a live cluster; verified locally (no cluster
available in this remote executor session) — same honest limitation
`dr-chaos-argocd.sh`'s own `docs/done/` entry recorded, not overclaimed here
either.

## PR

https://github.com/tooming/k8s-anywhere/pull/1576
