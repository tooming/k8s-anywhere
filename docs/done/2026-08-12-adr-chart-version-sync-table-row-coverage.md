# Extend `adr-chart-version-sync-check.sh` to cover ADR-0034's table-row self-tracking shape

(CHARTER **Core Values** §"Everything as code" / mechanical-guard-over-skills;
executor-fallback cycle 2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR
role, after PLANNER (no ungroomed issues, no `docs/roadmap/incoming/` files) and
ARCHITECT (zero un-RFC'd 🟡 items in ROADMAP.md, no open `adr-audit` issues, this
week's `docs/industry/2026-W33-digest.md` already refreshed earlier today) both had
no lever left to pull, and UPGRADE-DRAFTER's own WIP cap (one open `upgrade/*` PR at
a time, per WAYS-OF-WORKING.md §4) was already spent this run by PR #1171 (`upgrade/
ksm-chart-8-2-0-to-8-3-0`, merged). Now/next's six remaining ROADMAP items were all
re-confirmed gated (three sequential Forgejo-migration items requiring live-cluster
verification per their own item text; the `verifyImages` Enforce flip and O4
CI-rejection-gate item both blocked on unconfirmed maintainer-confirmation issue
#631; the legacy capstone `Deployment` removal blocked on unconfirmed issue #633 —
both re-checked directly, last comment 2026-08-11, still not observed).

## The footgun this closes

`scripts/adr-chart-version-sync-check.sh` already guards one self-tracking shape — a
two-line `- **Chart:** ... pin lives in ...` bullet — after ADR-0020 and ADR-0021 both
went stale once with nothing catching it (PR #616), and ADR-0023 repeated the exact
same failure mode later (chart bumped `1.11.0` → `1.11.1` in PR #1101 without the ADR
prose following, caught by a manual sweep). ADR-0034 introduced a **second**
self-tracking shape when it landed (2026-08-07): a per-component Markdown table where
four rows (Pyroscope, Alloy, kube-state-metrics, node-exporter) cite
`` `gitops/platform/<x>.yaml`, `targetRevision: VERSION` `` inline in one table cell —
and this shape had **zero** mechanical coverage. This run's own earlier cycle
(`upgrade/ksm-chart-8-2-0-to-8-3-0`, PR #1171) had to hand-edit that exact table row
when bumping kube-state-metrics `8.2.0` → `8.3.0`, with nothing in `make ci` that
would have caught it had the edit been missed — the identical "self-tracking note can
silently drift, undetected" failure mode already proven to recur (ADR-0020 → ADR-0021
→ ADR-0023), just in a table instead of a bullet.

## What changed

Extended `scripts/adr-chart-version-sync-check.sh` with a second scan (behind a
shared `check_pin()` comparator function, replacing the inline compare/report logic
duplicated between the two shapes) that finds every table-row cell matching
`` `gitops/....yaml`, `targetRevision: VERSION` `` across every ADR — no hardcoded
component or ADR list, self-maintaining exactly like the existing bullet-shape scan.
Verified directly against the real repo: the four ADR-0034 rows (Pyroscope, Alloy,
kube-state-metrics, node-exporter) are now checked and all currently match their live
`gitops/platform/*.yaml` pins; the three existing bullet-shape ADRs (0020/0021/0023)
are unaffected, still checked exactly as before. Mimir/Loki (`targetRevision: main`,
no `.yaml` path token) and Tempo (a raw `image:` tag, not a `targetRevision`) are
correctly *not* matched by either shape — they're point-in-time image-tag records
tracked elsewhere (ADR-0006's Re-evaluation log / `context.md`), not this convention.

Added two new fixture pairs (`tests/fixtures/adr-chart-version-sync/table-in-sync/`,
`table-drift/`) mirroring the existing bullet-shape fixtures' structure exactly, and
five new `tests/drift-adr-sync-checks.bats` assertions: the two new fixtures pass/fail
as expected, plus a real-repo assertion that ADR-0034's four table rows are now
actually scanned (`*"adr-0034"*` + `*"table row"*` in the output). The
`PostToolUse` hook (`scripts/adr-chart-version-sync-hook.sh`) needed no change — it
already shells out to this script on every `docs/decisions/`/`gitops/` edit, so it
picks up the new coverage automatically.

Behavior-preserving for the existing shape: the "no ADR uses the self-tracking..."
message wording was kept byte-identical (checked against the existing bats assertion
that greps for it) even though the check now covers two shapes, since that message
only fires when *neither* shape matched anything.

`make ci` passes locally (drift/lint/doc checks; `bats`/`kustomize`/`terraform` aren't
installed in this session per CLAUDE.md, they run in GitHub Actions on this PR).

## PR

<!-- filled in after PR creation -->
