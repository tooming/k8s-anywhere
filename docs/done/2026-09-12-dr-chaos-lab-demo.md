# Fault-injection drill against the `lab-demo` pod

Same Q12 gap-narrowing found live 2026-09-12, this item covers `lab-demo`,
the fourth and final always-on component named in Q12's gap — the last of
the three follow-ups to `dr-chaos-argocd` (2026-09-11), after
`dr-chaos-cert-manager` and `dr-chaos-traefik` (both 2026-09-12). After
this item, every one of the lab's four always-on components has a
fault-injection drill.

**Scope:** added `scripts/dr-chaos-lab-demo.sh` mirroring
`scripts/dr-chaos-argocd.sh`'s exact shape (same `confirm_or_abort`/
`DR_ASSUME_YES` gate, same `retry`/`fail` helpers, same
`lib/kctx.sh`/`lib/colors.sh`/`lib/confirm.sh` sourcing) for the chaos +
self-heal steps: kills the live `hello` pod in the `lab-demo` namespace
(selector `app: hello` — the real, live label `gitops/apps/demo/deployment.yaml`
sets, confirmed directly), then polls for a new Ready pod (different UID).

**Deviation from the ROADMAP item's original plan, found live while
building it:** the item text said to reuse `lab-health-check.sh`'s HTTP
probe pattern, same as the Traefik drill. Checking `gitops/apps/demo/`
directly first found this doesn't apply — `lab-demo` has no `Service` or
`IngressRoute` manifest at all (`deployment.yaml`'s own header comment
says so explicitly: "no Service/IngressRoute ever existed to reach its web
UI"), so there is no HTTP front-door URL to probe. Adapted the recovery
predicate instead: `kubectl exec`s into the new pod and `cat`s the
ConfigMap-mounted `/usr/share/nginx/html/index.html` directly, grepping
for the real `lab-demo-hello` ConfigMap content ("Hello from GitOps") —
confirmed directly against the live `configmap.yaml` and `deployment.yaml`
manifests rather than guessed. This is a stronger check than pod-`Ready`
alone (it also confirms the `ConfigMap` volume actually re-attached after
the pod recreated), and needs no live-cluster verification caveat the way
the cert-manager drill's selector did, since every piece of it (the label,
the mount path, the ConfigMap content) was confirmed directly from the
real manifests, not assumed.

Also added: a `make dr-chaos-lab-demo` target under the Makefile's
"Disaster recovery" section; guard-only bats coverage in
`tests/dr-guards.bats` (unknown-usage/no-confirmation-refusal paths only,
same non-destructive pattern as the three prior `dr-chaos-*.sh` scripts —
never actually invoking a live cluster from `make ci`); a `docs/DR.md`
section documenting it and its differing recovery-predicate shape; and a
final update to `docs/dora-audit-readiness.md`'s Q12 **Answer**/
**Evidence**/**Gap** fields — with all four always-on components now
covered, the **Gap** field states plainly that coverage is closed for what
this lab's components can honestly demonstrate, while still naming what
this was never meant to be (a TLPT-style adversarial/penetration test) and
what remains genuinely unverified (the cert-manager drill's own selector).

`make ci` passes (all bats/lint/validate/drift checks green; the new
script requires a live cluster and is never invoked from CI, same as
every other `dr-*.sh` script). Requires a live cluster; verified locally
(no cluster available in this remote executor session) — same honest
limitation the three prior `dr-chaos-*.sh` scripts' own `docs/done/`
entries recorded, not overclaimed here either.

## PR

https://github.com/tooming/k8s-anywhere/pull/1578
