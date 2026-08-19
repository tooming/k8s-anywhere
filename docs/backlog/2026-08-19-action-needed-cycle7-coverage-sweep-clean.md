# [Action needed] Now/next still gated; coverage/hardening + TRIAGER + JANITOR sweep clean (cycle 7)

Autonomous scheduled executor run, cycle 7 of this session (same run that
already landed PRs #1268-#1273 in cycles 1-6: an honest cycle-1 record, an
ARCHITECT digest refresh, and four UPGRADE-DRAFTER currency/CVE bumps —
Vault, Grafana, CI Terraform, Oracle-workflow Terragrunt). Per
`executor.prompt.md` STEP 8's "widen the lens" guidance, this cycle
deliberately tried angles not yet exercised this session — TRIAGER and
JANITOR — plus a broad local coverage/hardening sweep, instead of repeating
another dependency-currency bump.

## Now/next re-checked (unchanged from cycle 1)

All three remaining `ROADMAP.md` "Now / next" items re-confirmed gated,
verified directly against current file content (not assumed, ADR-0004):

- **GitLab→Forgejo script/Makefile rename** (`ROADMAP.md:1147`) — the
  2026-08-17 investigation note is still current: the auth model changes
  (HTTPS+PAT → SSH deploy key), there is likely no Forgejo-TLS equivalent to
  rename to, and `make up`'s bootstrap sequence still calls the GitLab
  targets. All three findings need live-cluster verification this
  clusterless session cannot provide.
- **GitLab decommission** (`ROADMAP.md:1201`) — deliberately sequenced after
  the rename above; unchanged.
- **Capstone legacy `Deployment` removal** (`ROADMAP.md:5998`) — still gated
  on issue #633 (re-checked via `issue_read`: still `state: OPEN`, no new
  confirmation comment since 2026-08-17).

Issue #631 (the other maintainer-confirmation gate this repo's Now/next
history references) is confirmed **closed** (`state_reason: completed`,
closed 2026-08-18 by PR #1223) — already reflected in the current Now/next
status note, not a new finding, checked here only to rule out stale gating
info.

## TRIAGER angle

`list_issues(state=open)` returns exactly two issues, both pre-existing
standing maintainer-confirmation gates with no new activity to triage:
#1229 (KUBECONFIG Forgejo Actions secret, O4 rejection-gate) and #633
(capstone Rollout promotion, above). No new issue reports, no duplicates to
close, nothing to label or route.

## JANITOR angle

Considered three candidates, all out of scope for a bounded one-cycle
cleanup:

1. **`docs/dependency-tree.md` has no mechanical drift check.** Confirmed
   directly — no `*-check` Makefile target or `tests/drift-detectors.bats`
   entry covers this file (unlike `README.md`'s stack table, which
   `readme-check` does cover). A prior cycle (2026-08-07, the stale
   `auto/action-needed-cycle13-doc-precision-lane-slowing` branch, cleaned
   up this cycle — see below) flagged the same gap and scoped it out as
   "better scoped as its own future item than rushed shallow here"; this
   cycle reached the same conclusion independently. The file is a 488-line
   two-diagram Mermaid document (runtime integration graph + day-0
   bootstrap chain) — a real drift check would need to parse node/edge
   labels against actual `gitops/` directory names and script references,
   closer in shape to `lab-ui-check` than a one-line grep. Left as a real,
   named candidate for a future dedicated cycle rather than rushed into
   this one.
2. **Two orphaned `auto/*` branches with no open PR** —
   `auto/pr-creation-diagnostic-test` (a single commit explicitly titled
   "to be discarded", left over from a prior PR-creation-500 investigation)
   and `auto/action-needed-cycle13-doc-precision-lane-slowing` (a stale
   2026-08-07 `[Action needed]` record, now superseded by this session's
   own fresher cycle-1 record, PR #1268). Both were rebased onto current
   `main` by this session's `make rebase-prs PUSH=1` (keeping the branch
   pointers current is the script's own job), but **branch deletion is
   blocked** at the git-proxy level (`git push origin --delete` returned
   HTTP 403) — a destructive git operation this session's own operating
   constraints reserve regardless of what `CLAUDE.md`/`WAYS-OF-WORKING.md`
   grant. Recorded here rather than silently dropped or worked around.
3. **Full `make ci` coverage/hardening sweep** — ran every fast local
   drift-check target that doesn't require the bats/kustomize/terraform
   toolchain missing from this clusterless sandbox (`readme-check`,
   `lab-ui-check`, `envoy-egress-allowlist-check`,
   `appset-list-coverage-check`, `workflow-timeout-check`, `roadmap-check`,
   `markdown-links-check`, `ci-parity-check`,
   `securitycontext-tests-check`, `networkpolicy-tests-check`,
   `observability-tests-check`, `yq-raw-check`, `yq-variant-guard-check`,
   `git-fixture-isolation-check`, `drift-detectors-tests-check`,
   `hook-scripts-coverage-tests-check`, `routines-check`,
   `routines-author-check`, `rollouts-plugin-list-check`,
   `analysistemplate-step-count-check`, `mimir-readonly-root-check`,
   `probe-timeout-check`, `adr-followup-check`,
   `context-doc-version-sync-check`, `docs-done-pr-link-check`,
   `kustomize-orphan-check`, `yqs-lib-check`, `ok-bad-lib-check`, plus the
   network-tolerant `adr-chart-version-sync-check` and
   `adr-image-pin-sync-check`) — all green, zero drift signals.
   `helm-chart-pin-check`/`argocd-crd-ssa-check` self-skip in this sandbox
   (no mikefarah/yq or helm binary installed locally — a known,
   already-documented local-only gap; both run for real in GitHub Actions
   CI on every PR).

## Why an honest record, not manufactured work

Per `ROADMAP.md` rule #9 / `executor.prompt.md` STEP 6b: an `[Action
needed]` record is the sanctioned deliverable when every avenue this cycle
tried — Now/next re-check, TRIAGER, JANITOR, and a broad local
coverage/hardening sweep — comes up clean or out-of-bounded-scope, rather
than forcing a risky or oversized change into one run. The run continues
per STEP 8 — this is not a stopping point.

## PR

https://github.com/tooming/k8s-anywhere/pull/1274
