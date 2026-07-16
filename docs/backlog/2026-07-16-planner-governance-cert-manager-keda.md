# Planner run — 2026-07-16 — governance LimitRange gap (cert-manager + keda)

## What triggered this run

This was the executor routine reaching the planner role via the STEP 6b fallback
chain. The "Now / next" lane was fully starved — every remaining unchecked item was
gated:

- `verifyImages ClusterPolicy — Audit → Enforce flip` — blocked on `auto/cosign-ci-sign-step`
  merging AND a live-cluster `.sig` tag confirmation, neither verifiable remotely.
- `O4 CI gate — verify-image-rejection job` — blocked on the enforce-flip item above
  (its own executor note requires `grep -q "validationFailureAction: Enforce"` on the
  policy file to return 0 first; confirmed still `Audit` in the working tree).
- `Capstone pipeline re-wire — Artifactory → Harbor` — blocked on a maintainer
  confirmation that the Harbor footprint fits the 12 GB budget on the live cluster.
- `Decommission Artifactory manifests` — blocked on the Harbor re-wire item above.
- `Remove legacy capstone Deployment` — blocked on a maintainer confirmation that the
  Argo Rollouts canary pipeline was exercised end-to-end (a live Kargo promotion) on
  the real cluster.
- `ADR-0017 audit — vault PSA-restricted` (🟡) — explicitly marked "the executor skips
  this item" until the upstream Vault Helm chart drops `cap_ipc_lock`; not architect
  work, no RFC to write.

No open PRs, no open issues (nothing to groom via intake), and no pending
`docs/roadmap/incoming/` files from the architect. A prior planner fallback run
earlier today (`docs/backlog/2026-07-16-planner-hook-scripts-negative-path.md`)
already mined the obvious coverage/hardening gap it found; that item has since been
built and checked off, so this run needed a fresh gap analysis rather than
re-surfacing the same lead.

## Gap analysis

Delegated a repo-wide CHARTER-vs-actual-state sweep (Explore agent) covering: O2
(default-deny + PSS-restricted) namespace-by-namespace against ADR-0017's table; O5
(dashboard coverage) against every auto-synced `Application`; doc drift in
`docs/dependency-tree.md` and the README stack table; ADR re-evaluation markers; and
scripts lacking bats coverage.

- **O2**: closed — all 29 `gitops/**/namespace.yaml` files are either `restricted`
  with zero carve-out or have an explicit, dated ADR-0017 row with a stated flip
  condition. No orphaned or undocumented-weaker-profile namespace found.
- **O5**: closed — every auto-synced `Application` has a matching
  `grafana/dashboards/lab-<name>.json`, and `tests/dashboard-coverage.bats` already
  asserts a real-datasource panel for each, including the newest components
  (cert-manager, KEDA).
- **Doc drift**: no material gap — `docs/dependency-tree.md` and the README already
  cover every gitops subsystem including cert-manager-root-ca / lab-gateway-certificate
  (a `make ci` local hint flags those two Application *names* as absent from the
  README's mechanical stack-table substring check, but the functionality is already
  prose-documented there — cosmetic, not a real content gap, and too small on its own
  to justify a separate PR this run).
- **ADR re-evaluation**: ADR-0019 (Kyverno) and ADR-0022 (Trivy Operator) both carry
  "re-evaluate per chart upgrade" carve-outs, but confirming whether their pinned
  chart versions have since dropped the carve-out condition needs a live upstream
  chart-docs fetch — not clusterless-deliverable this run.
- **Scripts vs bats**: every `scripts/*.sh` file is referenced by name in at least one
  `tests/*.bats` file — no gap (the earlier-today hook-scripts run closed the last of
  this).
- **New gap found, not on the initial checklist**: cross-checking
  `gitops/platform/governance-appset.yaml`'s namespace list against the always-on
  auto-synced `Application` set turned up two namespaces with no governance
  LimitRange leaf: `cert-manager` (ADR-0028) and `keda` (ADR-0029). Both landed after
  RFC #294's original standard-tier fan-out was already complete and were never
  folded in — every other always-on namespace (including the later-landed `harbor`,
  `envoy-gateway-system`, `node-exporter`) has a `gitops/governance/<ns>/` leaf; these
  two don't. `docs/dependency-tree.md`'s governance note names only `tidb`,
  `longhorn-system`, `istio-system`, `inkless` as intentional on-demand exceptions —
  cert-manager/keda aren't on that list, confirming this is an oversight, not a
  deliberate carve-out.

## Groomed into

One 🟢 ROADMAP item, no prerequisites, inserted at the very top of *Now / next* (so
the next executor run picks it up before the still-gated items below it):
`auto/governance-cert-manager-keda` — mirrors the existing
`auto/harbor-governance-limitrange` pattern exactly (shared
`base/limitrange-standard.yaml`, no per-namespace `limitrange.yaml` needed).

## Lane health after this plan PR merges

The six previously-gated items remain gated (nothing here unblocks them — they
genuinely need a maintainer's live-cluster confirmation or another PR to merge
first). The new item is immediately buildable and clusterless, so the next executor
run has real 🟢 work without needing to fall through the chain again.

## PR

PR #449 — https://github.com/tooming/k8s-anywhere/pull/449
