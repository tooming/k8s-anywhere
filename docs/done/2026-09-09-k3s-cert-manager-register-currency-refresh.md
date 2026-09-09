# `docs/dependency-register.md`'s k3s and cert-manager rows' "Last reviewed" dates re-confirmed against live upstream releases

Found live 2026-09-09 (executor run, STEP 6b JANITOR-adjacent lens: a coverage/hardening
sweep for stale-looking currency data in `docs/dependency-register.md` — a genuinely
different angle from the prior run's exhausted lenses, which had already tried
removed-component leftover rationale, incident-log follow-ups, ADR flip-condition
staleness, docs-vs-manifest cross-checks, infra/CI tooling currency, CI-workflow
concurrency-safety, and ROADMAP legacy-item trimming — see
[docs/backlog/2026-09-08-action-needed-cycle26-workflow-safety-sweep-exhausted.md](../backlog/2026-09-08-action-needed-cycle26-workflow-safety-sweep-exhausted.md)).

## What was found

`docs/dependency-register.md`'s own stated purpose is to be "a single, queryable
register" of third-party dependency currency, with a "Last reviewed" column per row.
Two of its 7 rows — k3s and cert-manager — still carried a `2026-09-03` "Last reviewed"
date, even though a prior cycle in this same run's history
([docs/backlog/2026-09-08-action-needed-cycle17-doc-drift-sweep-exhausted.md](../backlog/2026-09-08-action-needed-cycle17-doc-drift-sweep-exhausted.md))
had already re-verified both components' currency on 2026-09-08 (via `git ls-remote
--tags` against their upstream repos) and found no bump due — but that finding was
recorded only in a `docs/backlog/` narrative file, never written back into the register
itself. That left the register's own "queryable" record silently understating how
recently these two rows had actually been checked, undermining the exact gap this file
exists to close (`docs/dora-audit-readiness.md` Q14, "a register of ICT third-party
dependencies").

## What this cycle did

Independently re-verified both components' currency directly against their live GitHub
Releases pages (not merely repeating the prior cycle's claim):

- **k3s** — `github.com/k3s-io/k3s/releases`: the newest stable (non-rc, non-alpha) tag
  is `v1.36.4+k3s1`, released 2026-08-27 — exactly this repo's current pin on both
  backends (`infra/modules/k3d-cluster/k3d-config.yaml.tftpl`,
  `infra/modules/oracle-k3s-cluster/cloud-init.yaml`). The only newer entries are
  `v1.37.0-rc*` pre-releases, not a stable cut. No bump due.
- **cert-manager** — `github.com/cert-manager/cert-manager/releases`: the newest stable
  release tag is `v1.21.1`, released 2026-07-29 — exactly this repo's current pin
  (`gitops/platform/cert-manager.yaml`'s `targetRevision: 1.21.1`). No newer GHSA has
  been published against it since the register's own 2026-09-03 full-sweep entry. No
  bump due.
- **ArgoCD chart** (`argo-cd-10.8.2`, `github.com/argoproj/argo-helm/releases`) was also
  spot-checked for completeness: already current and already dated 2026-09-08 in the
  register — left unchanged.

Updated both rows' "Last reviewed" cells to a new `2026-09-09` entry recording this live
re-confirmation (with the prior 2026-09-03 entry kept as `Prior entry: ...`, matching
every other row's own dated-chain convention — see the ArgoCD/Traefik/Cilium rows for
the same shape). No pin, chart, or manifest change — this is a doc-currency-accuracy fix
only, closing the gap between "checked" and "recorded as checked."

## Verification

`make ci` green, including `scripts/dependency-register-check.sh`'s "Last-reviewed sync"
gate (the new dates are strictly newer than either cited ADR's own Re-evaluation log
entries, so the mechanical guard still passes) and its Scope-note arithmetic check
(unchanged — row/ADR counts untouched by this edit).

## PR

auto/k3s-cert-manager-register-currency-refresh
