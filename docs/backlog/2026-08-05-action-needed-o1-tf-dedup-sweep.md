# [Action needed] Now/next still gated; O1 ground-truth + Terraform dedup sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds exactly 3 unchecked `[ ]` items,
unchanged from the prior cycles today and yesterday:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (confirm a real
   GitLab CI run signed and pushed an image to Harbor).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (confirm an Argo
   Rollouts canary + Kargo promotion has run end-to-end).

Re-checked both issues fresh this run: still open, still unconfirmed. Latest
comments (2026-08-04T00:15 UTC) show the maintainer actively working the root
blocker for both — no GitLab Runner had ever been registered against this
lab's GitLab instance — via open PR
[#980](https://github.com/tooming/k8s-anywhere/pull/980)
(`feat/gitlab-runner-and-registry-port-fix`, human-authored, `mergeable_state:
clean`, still open, its own test plan notes the full push+sign confirmation
was still in progress as of that PR's last update). Not an agent-prefixed
branch, so it's the maintainer's own in-progress work — nothing for this
session to finish on it. No new comment landed on either issue since the
prior cycle's check.

## This cycle's fresh angle (not a repeat)

Picked up the two untried lenses the prior two cycles' own "what would
unblock further work" sections flagged (`2026-08-04-action-needed-cycle8-...`
and `...-charter-o2-o3-o5-deep-verify.md`): a ground-truth re-derivation for
CHARTER Objective **O1**, and a Terraform-module-level duplication sweep.

- **O1 ("Tier 1 next-wave deployed" — Kyverno, Argo Rollouts, Velero, Trivy
  Operator each need an auto-synced Application + ADR + real-metric dashboard
  + bats coverage).** Verified all four directly against the repo rather than
  trusting `make ci`'s presence check alone:
  - Applications: `gitops/platform/kyverno.yaml`,
    `gitops/platform/argo-rollouts.yaml`, `gitops/platform/velero.yaml`,
    `gitops/platform/trivy-operator.yaml` — all four exist.
  - ADRs: `adr-0019-kyverno-admission-engine.md`,
    `adr-0020-argo-rollouts-progressive-delivery.md`,
    `adr-0021-velero-backup-restore.md`,
    `adr-0022-trivy-operator-supply-chain.md` — all four exist.
  - Dashboards: `lab-kyverno.json`, `lab-argo-rollouts.json`,
    `lab-velero.json`, `lab-trivy.json` — all four exist.
  - Bats coverage: `tests/kyverno.bats`, `tests/argo-rollouts.bats`,
    `tests/velero.bats`, `tests/trivy-operator.bats` — all four exist (each
    also has its own `securitycontext-<name>.bats`/`networkpolicy-<name>.bats`
    companion, beyond O1's own bar).
  4 of 4 components fully satisfy all four O1 requirements — genuinely met,
  matching CHARTER.md's own line 171 claim ("Objective O1, met ahead of its
  2026-12-31 date").
- **Terraform-module-level duplication sweep.** `find infra -name '*.tf'`
  returns 12 files across 4 modules (`argocd`, `gitlab-config`, `k3d-cluster`,
  `oracle-k3s-cluster`; 522 lines total — a small, already-modular footprint).
  `md5sum` across all 12 shows zero identical-file pairs (extending the prior
  cycle's `gitops/` kustomization-file dedup check, which also found no
  duplicates, into `infra/`). Resource-block density is also low enough that
  a plausible duplication candidate would already stand out by file size
  alone — `oracle-k3s-cluster/main.tf` (12 resource/data blocks, the only
  cloud-backend module) and `k3d-cluster`/`argocd`/`gitlab-config` each cover
  a genuinely distinct concern (localhost bootstrap, cloud bootstrap, ArgoCD
  install, GitLab runner config) with no copy-pasted block structure between
  them. No janitor-sized extraction survives scrutiny here either.

Also re-ran the full local `make ci` clusterless gate set this cycle (lint,
readme-check, lab-ui-check, roadmap-check, markdown-links, ADR chart-version
sync, ADR image-pin sync, `context.md` version sync, orphaned-kustomize,
routines apply-sync, `ci-parity-check`, and the rest of the drift-detector
suite) — all green, zero drift signals. Checked for open `adr-audit`-labeled
issues (architect's own stranded-audit signal): zero. No open `plan/*`/`arch/*`
PR already carries a refill.

## Assessment

Both untried lenses came up clean. Combined with the prior two cycles' O2/O3/
O5 ground-truth re-derivation and full fallback-chain walk, every CHARTER
Objective except O4 (the literal subject of the #631 gate) has now been
directly re-verified from repo state at least once in the last two days, not
just asserted from `make ci`'s own presence checks. The backlog is genuinely
healthy — starved only by the two standing maintainer-confirmation gates, not
by any undiscovered gap.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633 — PR #980 is
the live in-progress work toward that; (b) a new GitHub issue (ungroomed
intake); (c) a new upstream CVE/release firing a tracked ADR flip condition;
(d) a future cycle's fresh lens — the remaining genuinely-untried one is a
direct O4 ground-truth check once the Enforce flip itself lands (checking it
now would just re-observe the same Audit-mode state item 1 already documents).

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8 this
is not a stopping point — the run continues to the next cycle.
