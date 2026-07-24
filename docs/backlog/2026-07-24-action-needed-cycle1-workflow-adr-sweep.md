# [Action needed] Now/next still gated; GitHub Actions + ADR re-eval sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle (first cycle of 2026-07-24): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21.

## This cycle's fresh angle

Four checks not previously covered by the extensive prior-day sweeps
(`docs/backlog/2026-07-23-*.md`, 11+ cycles covering CI-tooling, O2
namespace coverage, CHARTER precision, secrets hardening, dependency-tree/
dashboard coverage, and the `drift-detectors.bats` monolith split):

1. **GitHub Actions supply-chain hardening (new lens).** Checked every
   `uses:` line across all 7 workflow files in `.github/workflows/` for
   commit-SHA pinning (vs. floating version tags, a real supply-chain risk
   if a tag is ever force-moved) and for an explicit least-privilege
   `permissions:` block. Result: all 7 workflows already declare
   `permissions:`, and every `uses:` line across `ci.yml`,
   `auto-update-prs.yml`, `oracle-cluster-apply.yml`,
   `oracle-cluster-apply-retry.yml`, and `pr-up-to-date.yml` is already
   pinned to a full commit SHA with a `# vX.Y.Z` comment (not a floating
   tag). No gap found.
2. **Loki `3.7.4` flip condition re-check.** The 2026-07-23 Mimir-bump cycle
   found `grafana/loki:3.7.4` on Docker Hub with no corresponding git tag
   or changelog entry, and explicitly declined to bump on unverifiable
   data — flip condition: "a real `v3.7.4` (or later) git tag / GitHub
   Release appears, or a CVE is filed against `3.7.3`." Re-ran
   `git ls-remote --tags https://github.com/grafana/loki.git` this cycle:
   still stops at `v3.7.3`, no `v3.7.4` tag. Condition has not fired — pin
   correctly held.
3. **ADR-0014 (Cilium) "missing Re-evaluation log" — investigated, false
   alarm.** Every other version-pin ADR bumped this week
   (0006/0008/0009/0012/0013/0016/0017/0018/0019/0020/0023/0028) carries a
   `## Re-evaluation log` section; ADR-0014 has none despite Cilium being
   bumped `1.16.6` → `1.17.18` (RFC #501). Checked the original ROADMAP item
   text (now in `docs/done/`): it explicitly reasoned "ADR-0014 already
   states 'chart cilium/cilium ≥ v1.16' so no ADR text change is needed" —
   the ADR pins a floor, not an exact version, so `1.17.18` still satisfies
   it without requiring a log entry. Correct as-is, not a gap.
4. **`:latest` image tags — re-confirmed, no new finding.** Grepped
   `gitops/` for `image:.*:latest` (5 hits: `inkless`, `s3manager`, demo
   `hotrod`, capstone `rollout.yaml`/`deployment.yaml`). All 5 were already
   explicitly triaged as intentional floating tags in prior cycles
   (`docs/backlog/2026-07-20-action-needed-lane-still-gated-cycle5.md`,
   `docs/done/2026-07-18-capstone-latest-tag-exclude.md`) — capstone's is
   its own CI-built image re-tagged per pipeline run, the rest are
   deliberately out of `helm-chart-pin-check.sh`'s scope. No new finding.

Also re-swept for untested scripts (`scripts/*.sh` each referenced in
`tests/`) — zero gaps, full coverage.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition (including Loki's
above); (c) a new GitHub issue of any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
