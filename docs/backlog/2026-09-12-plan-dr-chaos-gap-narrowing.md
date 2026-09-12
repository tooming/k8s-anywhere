# Planner note — 2026-09-12 — three new Q12 gap-narrowing items

## What triggered this

Reached via `executor.prompt.md` STEP 6b's PLANNER fallback, cycle 3 of
today's run (2026-09-12), after cycles 1–2 found the "Now / next" lane
genuinely empty (zero unchecked ROADMAP items) and no issue to groom. Rather
than repeat the same empty search a third time, this cycle re-read
`docs/dora-audit-readiness.md`'s own Q12 answer — freshly rewritten
2026-09-11 when `dr-chaos-argocd` shipped — and found it explicitly says its
own gap is "narrowed, not closed": one drill exists (ArgoCD's
application-controller); the other three always-on components
(cert-manager, Traefik, `lab-demo`) have none yet. That's real, concrete,
clusterless-buildable gap analysis, not a repeat of a search already proven
empty.

## What was added

Three new 🟢 ROADMAP items, each scoped as its own single-PR-sized unit
mirroring `dr-chaos-argocd`'s exact shape (script + Makefile target + guard
bats coverage + docs), per WAYS-OF-WORKING.md §3's size discipline:

1. `dr-chaos-cert-manager` — kills the cert-manager controller pod
   (`app.kubernetes.io/name=cert-manager` in the `cert-manager` namespace),
   asserts self-heal + ClusterIssuer/Issuer `Ready` again. Flagged
   explicitly as needing live label verification on the next cluster
   rebuild (same caveat this repo's own
   `allow-cert-manager-webhook-from-apiserver.yaml` already carries for a
   label assumption in the same namespace) — not asserted as confirmed
   (ADR-0004).
2. `dr-chaos-traefik` — kills the Traefik pod
   (`app.kubernetes.io/name=traefik` in `kube-system` — already a real,
   live selector this repo's own
   `gitops/argocd/networkpolicy/allow-argocd-server-from-gateway.yaml` uses
   today, not a new assumption), asserts self-heal + HTTP ingress recovery.
3. `dr-chaos-lab-demo` — kills the `hello` pod
   (`app: hello` in `lab-demo`, the real live label
   `gitops/apps/demo/deployment.yaml` sets), asserts self-heal + the demo
   endpoint serving its real content again. This is the item that should
   carry the final Q12 **Answer**/**Gap** update once all three land, since
   it's the natural "last of the four components" checkpoint — but each
   item's own scope text says to check the other two's merge state first
   so the Q12 update stays accurate regardless of merge order.

No issue was groomed (this was gap analysis, not intake grooming) — nothing
to close or label here.

## Why three items, not one

A single combined item covering all three components would very likely
cross WAYS-OF-WORKING.md §3's ~400-line-per-PR guidance once you count three
scripts + three Makefile targets + three bats-coverage additions + three
doc updates. Splitting by component mirrors how `dr-chaos-argocd` itself
was scoped (one component, one PR) and lets the executor build and land
each independently across separate cycles.

## What's still not covered

Q13 (test-result/remediation-deadline tracking) remains a real, unresolved
gap — `docs/dr-results-log.md` and its supporting library were removed
2026-09-07 with no replacement. Not turned into an item this cycle: unlike
Q12's narrow, concrete "kill this specific pod" instances, Q13 would need a
genuinely new mechanism designed (what counts as a "test result", what a
"remediation deadline" means for a fully-automated self-merging repo with
no human triage step) — that's an architect-shaped decision, not a
plainly-scoped executor item. Left for a future ARCHITECT-fallback pass to
consider as a 🟡 RFC candidate, not invented here without that decision.
