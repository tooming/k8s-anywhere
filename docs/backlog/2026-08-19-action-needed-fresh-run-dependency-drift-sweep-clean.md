# [Action needed] Now/next still gated; fresh-run currency + drift sweep clean

**Date:** 2026-08-19
**Cycle:** 1st cycle, new run (prior run on this same date reached 20 cycles —
see `docs/backlog/2026-08-19-action-needed-cycle20-envoy-gateway-register-completeness.md`
for its final state; this is a separate scheduled invocation starting fresh)

## What's blocked

Unchanged from the prior run's final state: the "Now / next" lane holds the
same three items —

1. `Rename scripts/gitlab-*.sh → forgejo-*.sh` — the item's own 2026-08-17
   investigation note stands: the auth model changed (HTTPS+PAT → SSH deploy
   key), Forgejo needs no TLS-bootstrap equivalent, and `make up`'s bootstrap
   sequence still calls the GitLab targets — all three need a live-cluster
   session to design/verify, not a clusterless rename.
2. `Decommission gitlab/docker-compose.yml + infra/modules/gitlab-config` —
   deliberately kept as a rollback path a beat longer than the rename, per
   its own text (mirrors the Artifactory-after-Harbor precedent). GitLab
   stopped 2026-08-17, only 2 days ago — no new information changes this
   judgment call this cycle.
3. `Remove legacy capstone Deployment` — still gated on issue #633
   (re-checked this cycle: still open, `updated_at` 2026-08-17T18:50:01Z,
   no new comment since the prior run's own re-check).

Issue #631 (the sibling maintainer-confirmation gate) is now **closed**
(confirmed 2026-08-18, closed by PR #1223) — re-verified directly this
cycle, not assumed.

## What was tried this cycle

A fresh dependency-currency + drift sweep, distinct from the prior run's
20 cycles (which covered ArgoCD, Garage, Grafana, RabbitMQ, Istio, Cilium,
Longhorn, Kargo, cert-manager, KEDA, External Secrets, Envoy Gateway, and a
register-completeness audit — see cycle 9-20's backlog notes):

1. **Kiali currency + GHSA check** — `github.com/kiali/kiali-operator` tags:
   `v2.30.0` (Aug 2, 2026) is still the newest stable tag, matching this
   lab's pin (`gitops/platform/kiali.yaml` `targetRevision: 2.30.0`).
   `github.com/kiali/kiali/security/advisories` has zero published
   advisories. No gap.
2. **Harbor currency + GHSA check** — `github.com/goharbor/harbor-helm` tags:
   `v1.19.2` (Aug 3, 2026) is still the newest stable tag, matching this
   lab's pin (`gitops/platform/harbor.yaml` `targetRevision: 1.19.2`). One
   new advisory since the register's last Harbor review (2026-08-03):
   GHSA-56j8-6qr5-cg75 ("About CVE-2026-4404", Low, published Apr 2026 —
   just newly indexed) — read directly: Harbor's own maintainers dispute
   this CVE outright ("harbor.yml.tmpl is a sample file... requiring custom
   passwords is standard practice, not a product defect"), no patched
   version listed, actively requesting the CVE be rejected. Not a real,
   actionable finding — nothing to bump or mitigate. No gap.
3. **k3s currency check** — `github.com/k3s-io/k3s` releases: `v1.36.3+k3s1`
   (Aug 4, 2026) is still the newest `1.36.x` stable tag (no `v1.36.4`, no
   `v1.37.0`), matching both pins (`infra/modules/k3d-cluster/
   k3d-config.yaml.tftpl`'s `rancher/k3s:v1.36.3-k3s1`,
   `infra/modules/oracle-k3s-cluster/cloud-init.yaml`'s
   `INSTALL_K3S_VERSION=v1.36.3+k3s1`) — matches ADR-0030's own
   2026-08-05 bump entry. No gap.
4. **Full local drift-check sweep** — ran every `scripts/*-check.sh` that
   doesn't require a live cluster (34 scripts: ADR/chart-pin sync,
   AppSet/dashboard coverage, CRD SSA, CI parity, docs/done PR-link, drift-
   detector test coverage, Envoy egress allowlist, git-fixture isolation,
   Helm chart pins, hook-script coverage, idle-issue guard, kustomize
   orphans, markdown links, Mimir read-only-root, NetworkPolicy tests, O5
   dashboard coverage, observability tests, `ok`/`bad` lib usage, probe
   timeouts, ROADMAP format, Rollouts plugin list, routines-author/
   routines-check, SecurityContext tests, workflow timeouts, yq raw/variant/
   lib guards) — all pass clean. The only 3 failures
   (`k3s-datastore-health-check.sh`, `lab-health-check.sh`,
   `ondemand-budget-check.sh`) are the expected "cluster unreachable" result
   for a clusterless session, not a real finding.
5. **`make readme-check` / `make lab-ui-check`** — both green.
6. **CHARTER Objectives spot-check** — O3 (`tests/dr-restore.bats` — 600s
   budget, 6 namespaces), O6 (`tests/capstone-demo.bats`), O7
   (`tests/dora-metrics.bats`) all have real, structurally-verified
   coverage already in place — confirmed by grep, not assumed.
7. **Bats-coverage completeness check** — cross-referenced every
   `scripts/*.sh` + `lib/*.sh` against `tests/` for at least one reference;
   zero scripts came back with no test reference at all.
8. **`docs/dora-audit-readiness.md` gap re-read** — every remaining "Gap:"
   line in the document (Q5, Q9/Q11 cadence, Q12 node-loss fault type, Q13
   remediation-deadline tracking) is either explicitly non-mechanical from a
   clusterless session (needs a live scheduler/cron, or a live cluster run
   to populate a log) or, for Q12's "node-loss" gap, not clearly
   distinguishable from the existing `make dr-test` full-rebuild coverage on
   a single-node lab (ADR-0005 — this lab has exactly one node by design, so
   "node loss" and "total outage" are close to the same event `dr-test`
   already exercises) — didn't force a speculative new drill script whose
   value over existing coverage isn't clearly established, per rule #9's
   "real, verifiable work, not busywork" bar.
9. **No un-RFC'd 🟡 items** — `grep -c '^- \[ \] 🟡' ROADMAP.md` → 0.
10. **No ungroomed open issues** — only #633 and #1229 are open, both
    correctly-labeled standing `[Action required]` trackers, not work
    requests.

## Why this is the honest deliverable

Every angle tried this cycle came up clean or already covered. Per
`executor.prompt.md` STEP 6b/STEP 8 and ROADMAP rule #9: recording this
honestly rather than fabricating make-work, then going straight back to
STEP 1 for the next cycle with a different lens.
