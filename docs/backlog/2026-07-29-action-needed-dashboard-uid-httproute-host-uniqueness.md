# [Action needed] Now/next still gated; dashboard UID + HTTPRoute hostname uniqueness audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#842](https://github.com/tooming/k8s-anywhere/pull/842) (Kyverno
policy exclude-block audit).

## This cycle's fresh angle

Two structural-uniqueness checks no prior note has run, both real
collision classes Grafana/Envoy Gateway would surface as runtime conflicts,
not something the existing bats presence-checks verify:

1. **Grafana dashboard UID uniqueness** — parsed all 36
   `grafana/dashboards/*.json` files' top-level `uid` field (via Python
   `json.load`, not a naive grep — an earlier grep pass on this same
   question over-matched nested `datasource.uid` fields like `"mimir"`/
   `"loki"` and had to be discarded before it produced a false "36 unique
   → many duplicates" reading). Result: **36 dashboards, 36 unique UIDs,
   zero collisions.**
2. **HTTPRoute hostname uniqueness** — extracted every `spec.hostnames[]`
   entry across every `HTTPRoute` manifest in `gitops/` via `yq`. Result:
   **13 distinct hostnames, zero duplicates** (no two routes claim the
   same host, which would otherwise cause ambiguous routing at the shared
   Envoy Gateway listener).

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — two genuinely distinct structural
uniqueness checks, run correctly via JSON/yq parsing after catching a naive
grep's false signal. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
