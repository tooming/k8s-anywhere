# [Action needed] Now/next still gated; janitor-lens duplication check also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (sixth cycle of 2026-07-26): all three still open, zero comments.

## This cycle's fresh angle

Read `routines/janitor.prompt.md`'s own priority order and tried its #2
candidate class — duplication — as a lens not yet tried fresh today: hashed
every `allow-*-intra-namespace.yaml` file across the six multi-component
namespaces that share ADR-0016's documented "broad `podSelector: {}`"
carve-out (`argocd`, `harbor`, `inkless`, `istio-system`, `longhorn-system`,
`tidb`, plus `observability`). All seven files hash differently — not because
the policy body differs (each is the same `podSelector: {}`
ingress+egress-within-namespace shape), but because each file's header
comment documents that namespace's own specific intra-namespace flows (e.g.
`argocd-server → argocd-repo-server (gRPC :8081)` vs. Harbor's
core/registry/jobservice/portal/database flows) — genuinely useful,
non-duplicated documentation, not copy-paste debt. Templating these into a
shared file would delete exactly the per-namespace rationale ADR-0016's
Carve-outs table cites as the reason each namespace gets this exception.
Correctly judged **not** a janitor candidate — a real "duplication" cleanup
here would destroy value, not add it.

No other footgun/duplication/dead-matter candidate was found either (this
matches every prior janitor-lens cycle's finding this week: full bats
coverage, no undocumented TODO/FIXME markers, no orphaned scripts).

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of any
size.

This note is this cycle's honest record — this run's sixth cycle today,
having now tried CVE research (5 cycles across PRs #729–#733), CHARTER
re-audit, GitHub Actions currency, and janitor-lens duplication checking,
all coming up clean — not a stopping point. The run continues to the next
cycle per `executor.prompt.md` STEP 8.
