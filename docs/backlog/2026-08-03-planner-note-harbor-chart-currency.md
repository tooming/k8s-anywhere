# Planner note — 2026-08-03 (Harbor chart currency)

## What this run did

Reached the planner role via `executor.prompt.md` STEP 6b: the "Now / next"
lane held only the same 3 items every recent cycle has found gated (on standing
maintainer-confirmation issues [#631](https://github.com/tooming/k8s-anywhere/issues/631)
and [#633](https://github.com/tooming/k8s-anywhere/issues/633), both re-verified
still open this cycle, no new confirmation comment). No ungroomed GitHub issues
existed to groom (only the two standing `[Action required]` issues above, which
are not intake). `docs/roadmap/incoming/` held no pending architect items.

Ran the ARCHITECT fallback role's own STEP 1 (weekly upstream-release sweep)
directly, checking real upstream release data (not training knowledge, ADR-0004)
for all 17 components in `routines/architect.prompt.md`'s checklist, plus Harbor
and Garage (not on that checklist but ADR'd — see the drift note below):
k3s, ArgoCD, Cilium, Vault, Envoy Gateway, Grafana, Longhorn, Valkey, RabbitMQ,
TiDB, Istio, Garage, Kyverno, Argo Rollouts, Trivy Operator, Velero, Harbor.

**16 of 17 were already fully current** — either just bumped this run's earlier
cycles (Envoy Gateway, cert-manager), or already tracking the latest upstream
stable release with no actionable delta (Cilium `1.18.12`, Vault `2.0.3`,
Grafana `13.0.3` — checked `13.0.4`/`13.1.1` too, neither is a security release,
so no audit warranted per `architect.prompt.md` STEP 2b's bar, Longhorn `1.11.3`
vs `1.12.0` — a minor GA feature release with no CVE and Longhorn is on-demand,
not urgent, Valkey `8.0.10-alpine`, RabbitMQ `4.3.4`, TiDB `v8.5.7`, Istio
`1.30.3`, Kyverno chart `3.8.2`/appVersion `v1.18.2`, Argo Rollouts `2.41.1`,
Velero chart `12.1.0`, Garage `v2.3.0` via `git ls-remote` against the GitHub
mirror). k3s's ADR-0030 was re-checked directly against `k3s-io/k3s`'s release
page — `v1.36.2+k3s1` is still the newest *stable* tag (only `v1.36.3-rc*`
pre-releases exist), consistent with that ADR's own 2026-07-28 audit #770 kept
decision — no new audit needed.

**One real delta: Harbor's chart shipped `v1.19.2` today** (2026-08-03,
verified via a full clone of `github.com/goharbor/harbor-helm` and a real
`git diff v1.19.1 v1.19.2`), one patch ahead of this lab's pinned `1.19.1`.
Not a CVE fix (ADR-0024's most recent audit, #774 2026-07-28, already confirmed
`1.19.1` sits past CVE-2026-4404's fix floor with a flip condition that this
bump doesn't trigger) — a routine appVersion `2.15.1`→`2.15.2` bump plus one
structural note worth recording: the chart's bundled-cache image repository
switched from `goharbor/redis-photon` to `goharbor/valkey-photon` upstream.
Added as a new 🟢 Now/next item (`auto/harbor-chart-1-19-2`) with full
implementation detail, following the same smallest-safe-delta pattern as the
`kro 0.9.2→0.9.3` / `cert-manager 1.21.0→1.21.1` bumps already in `## Done`.

**Bonus finding while verifying the Harbor bump:** `docs/dependency-tree.md`'s
harbor bullet says Harbor uses "platform Valkey for cache" — this contradicts
`gitops/platform/harbor.yaml`'s own header comment and live `redis.type:
internal` setting (Harbor uses its own bundled internal cache instance, not the
lab's shared `data`-namespace Valkey; the ADR-0018 exception has been documented
in that file since 2026-07-21 because ArgoCD's template-only rendering can't
resolve the chart's `lookup()`-based external-Valkey wiring). Folded the fix
into the same new ROADMAP item rather than a separate item, since it's a
one-line correction on the exact line the version-bump item already touches.

## Why no other action this cycle

`architect.prompt.md`'s own no-op clause ("no 🟡 items without RFCs AND no ADR
audits flagged") does not apply when reached via a starved-lane escalation
(`executor.prompt.md` STEP 6b) — but the sweep above genuinely found only one
actionable delta across 17 real upstream checks, so a single well-scoped
ROADMAP item is this cycle's honest, non-inflated deliverable rather than
manufacturing additional churn.

## What would unblock further Now/next work

Unchanged from every recent cycle: (a) a maintainer-confirmation comment on
#631 or #633; (b) a new GitHub issue of any size (ungroomed intake); (c) a new
upstream CVE/release firing one of the tracked ADR flip conditions.

This is this cycle's deliverable, not the run's stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8, which should pick
up the newly-added Harbor item directly.
