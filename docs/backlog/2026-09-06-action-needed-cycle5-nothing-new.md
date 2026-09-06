# [Action needed] Cycle 5 (this run): fallback chain exhaustively re-checked, nothing new found

This is the 5th cycle of this executor run. The prior 4 cycles each delivered a
real, merged PR:

1. `upgrade/kro-0.9.3-to-0.9.4` (#1441) — KRO chart currency bump.
2. `upgrade/grafana-12.10.4-to-12.11.2` (#1445) — Grafana chart currency bump.
3. `auto/ensure-bats-hook` (#1448) — mechanical recurrence-prevention fix for a
   real bug class found live this run (`make ci`'s unit gate silently
   self-skipping in this sandbox).
4. `auto/dora-kyverno-failurepolicy-fix` (#1449) — corrected a stale ADR-0004
   violation in `docs/dora-audit-readiness.md`.

This cycle re-ran the full STEP 6b fallback chain and found every lane empty:

- **ROADMAP "Now / next"**: still exactly the same 3 gated items as every prior
  cycle this run — the two sequential GitLab→Forgejo migration items (still
  genuinely blocked per `docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md`,
  re-verified this cycle: `make up`'s bootstrap sequence still calls
  `gitlab-up`/`gitlab-configure`/`gitlab-tls-bootstrap`, not a Forgejo
  equivalent) and the capstone `Deployment` removal (gated on issue #633, no
  new confirmation comment since 2026-08-25).
- **PLANNER**: zero ungroomed issues (only #633/#1229, both already
  fully-labeled standing `[Action required]` gates, re-checked directly via
  the REST issues API — neither has a new comment). No `docs/roadmap/incoming/`
  files pending. No open `plan/*` PR to duplicate.
- **ARCHITECT**: zero un-RFC'd 🟡 items — `grep '🟡' ROADMAP.md` finds only
  struck-through, already-resolved historical entries.
- **TRIAGER**: nothing to triage (same 2 issues, already labeled).
- **DOC-DRIFT-AUTHOR**: `make ci` shows zero README/lab-UI/dependency-tree
  drift warnings.
- **UPGRADE-DRAFTER**: swept every `gitops/**/*.yaml` Helm chart source this
  run (cilium, cert-manager, kyverno, argo-rollouts, harbor, vault, velero,
  longhorn, tidb-operator/tidb, kro, external-secrets, keda, istio×4, kiali,
  trivy-operator, kargo, ack-s3, moto, alloy, grafana, kube-state-metrics,
  node-exporter, pyroscope, loki, tempo, k3s) plus Terraform-bootstrapped
  ArgoCD — every one is current as of a real, direct upstream check, or is
  pinned by a binding ADR "hold at line" decision not yet flip-triggered
  (Cilium 1.18.x, Longhorn 1.11.3, TiDB Operator 1.6.x, TiDB DB v8.5.x — all
  re-checked this run, none met their own flip condition). The one candidate
  found (ArgoCD chart `10.5.0` → `10.8.0`) was deliberately **not** attempted:
  it spans multiple minor releases and this remote session's page-fetch
  tooling could not reliably diff its large `values.yaml` across tags (a
  fetch of the target tag's file came back truncated, omitting real,
  known-to-exist top-level keys like `repoServer`/`applicationSet` —
  verified against this repo's own already-pinned `values.yaml`, which uses
  those exact keys). Given ArgoCD is the platform's own GitOps control
  plane, a bump this session can't verify safely was skipped rather than
  asserted safe (ADR-0004).
- **JANITOR** (the two real fixes above already delivered this run): a further
  sweep this cycle found no untested scripts (every `scripts/*.sh` file has at
  least one bats reference), no further stale-doc claims found in a spot check
  of `docs/00-architecture.md` (its GitLab/Forgejo caveat is already an
  intentional, accurate, cross-referenced note — not drift), and every
  `SessionStart`/`PostToolUse` hook script already has bats coverage.

## What's blocked, and what would unblock it

- **Issue #633** — needs a live-cluster session to observe an actual Kargo
  promotion of the capstone `Rollout` complete end-to-end. Extensive history on
  this issue (13 comments from prior live-cluster sessions) shows real, hard
  infrastructure blockers (host resource exhaustion when Harbor+Kargo run
  together, etcd write-pressure, envoy-gateway control-plane instability —
  each found and fixed in turn) rather than a simple retry away.
- **Issue #1229** — needs a human (or a live-cluster session with the
  necessary access) to generate a service-account kubeconfig and set it as a
  Forgejo Actions secret. The RBAC half is already built and merged
  (`gitops/apps/capstone/ci-verify-rejection-rbac.yaml`, PR #1403); only the
  live steps in `docs/runbooks/2026-09-04-ci-verify-rejection-kubeconfig.md`
  remain.
- **ArgoCD chart bump** — needs either a session with more reliable
  large-file-diffing tooling than this sandbox's `WebFetch`, or a maintainer
  decision that a smaller, single-step bump (`10.5.0` → `10.6.x` first) is an
  acceptable lower-risk path for a future cycle to attempt.

No maintainer action is strictly required to unblock any of these beyond what
issues #633/#1229 already ask for — this note exists per
`executor.prompt.md` STEP 6b as the honest record of an exhausted fallback
pass, not a new escalation.

This is an autonomous scheduled run (k8s-anywhere `executor` routine).
