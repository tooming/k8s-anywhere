# Planner note — 2026-08-06 — ArgoCD chart `10.2.3` → `10.3.0` currency gap found, added to Now/next

## Context

Reached via `executor.prompt.md` STEP 6b: this run's cycle found all three
standing *Now / next* items still gated on unconfirmed maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-checked this
cycle — both still open, most recent comments 2026-08-06 07:38 UTC, no new
signal). Zero open issues need grooming (all 3 open issues — #631, #633,
#1034 — are standing `[Action required]` maintainer-confirmation gates, not
user work requests or `rfc`-labeled architect decisions). Zero files under
`docs/roadmap/incoming/`. Zero open PRs to de-dupe against.

Per rule #9's "split the gate" / STEP 8's "try a lens the last pass didn't"
guidance, checked a component whose `docs/dependency-register.md` entry
stood out from the rest of the table: ArgoCD's own "Last reviewed" column
read *"not dated in ADR (no Re-evaluation log)"* — unlike every other
ADR'd component, which cites a specific date and PR. That's not itself a
defect (ADR-0001 predates the re-evaluation-log convention and ArgoCD chart
bumps are tracked as ROADMAP items, not ADR log entries), but it meant
ArgoCD hadn't been individually re-checked in today's multiple currency
sweeps (which explicitly named Kyverno/RabbitMQ/Valkey/Garage/GitHub
Actions/Mimir/Grafana/Loki/Tempo/TiDB Operator/Longhorn but not ArgoCD
itself).

## Finding

`git ls-remote --tags argoproj/argo-helm` shows `argo-cd-10.3.0` newest on
the chart's tag line, one release ahead of the repo's pinned
`chart_version` default (`"10.2.3"`, landed 2026-08-05). A real clone diff
(`git diff argo-cd-10.2.3 argo-cd-10.3.0 -- charts/argo-cd/`) is
three lines across three files — `Chart.yaml`'s `version` field only
(`appVersion` stays `v3.5.0` — this is a same-appVersion chart repackage,
not an ArgoCD version bump), its changelog annotation, `README.md`'s
auto-generated table, and `values.yaml`'s bundled Redis dependency tag
(`8.2.3-alpine` → `8.6.4-alpine`). Confirmed the RFC #785 recurrence-guard
condition (`global.networkPolicy.create: false`, `infra/modules/argocd/values.yaml`)
is unaffected: the chart's own default for that key is unchanged (`true`)
between 10.2.3 and 10.3.0.

This is real, verified, low-risk currency work — not manufactured filler.
Added as a new 🟢 **Now / next** item (`auto/argocd-chart-10-3-0`), inserted
at the top of the list so the executor's next cycle picks it up immediately.
No RFC needed (routine dependency-register currency bump, same category as
the immediately-preceding 10.2.2→10.2.3 item already in ROADMAP.md's Done
history).

## What was NOT changed

ROADMAP.md's three standing gated items (verifyImages Enforce flip, the O4
GitLab CI rejection-gate job, capstone Deployment removal) are unchanged —
still correctly gated on #631/#633, no new maintainer signal to act on.
Nothing groomed from issues (none needed it). No `docs/roadmap/incoming/`
files existed to absorb.
