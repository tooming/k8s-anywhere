# Add a mechanical guard against stale self-tracking ADR "Chart + version" notes

(CLAUDE.md §"Every bugfix must prevent recurrence" — janitor fallback role, invoked
via `executor.prompt.md` STEP 6b after the executor's own "Now / next" lane came up
fully gated on maintainer-confirmation prerequisites, and the planner/architect/
upgrade-drafter/doc-drift fallbacks all came up with no further real deliverable
this run — a fresh gap-analysis sweep across ADR re-evaluation staleness, dashboard
coverage, NetworkPolicy/PSS coverage, chart-version drift, missing bats coverage,
and dependency-tree drift found nothing new, mirroring the immediately-prior run's
own exhaustive sweep.)

Two ADRs — ADR-0020 (Argo Rollouts) and ADR-0021 (Velero) — write their
"Chart + version" section in a deliberately self-tracking form: "pin lives in
`<gitops file>`'s `targetRevision` — this note read `<old value>` until the
`<date>` bump". This is different from the phrasing every other ADR with a
"Chart + version" section uses ("vX.Y.x, latest stable at executor pickup time"),
which is an intentional point-in-time decision record that never needs updating on
a later patch bump.

The self-tracking form already went stale once, undetected by any gate: PR #615
bumped Argo Rollouts' live pin `2.41.0` → `2.41.1` but, per the upgrade-drafter
role's explicit "you do NOT upgrade ADRs" scope boundary, deliberately left
ADR-0020's Chart + version note reading the old value — a real, already-present
doc-drift gap that PR #615's own body flagged, only fixed by a separate manual
janitor-fallback PR (#616) minutes later. Nothing mechanical would have caught a
future recurrence of the same class on either ADR-0020 or ADR-0021 (or any future
ADR that adopts the same self-tracking convention).

Added, mirroring this repo's existing drift-guard pattern (`adr-followup-check.sh`
is the closest structural analog — an ADR-prose content check with a fixture-driven
`ROOT` override):

- `scripts/adr-chart-version-sync-check.sh` — discovers every `docs/decisions/
  adr-*.md` file using the self-tracking "pin lives in `<file>`'s `targetRevision`"
  phrasing (no hardcoded list — self-maintaining as new ADRs adopt the convention),
  extracts the ADR-stated chart version and the referenced gitops file, and fails if
  the live `spec.source.targetRevision` no longer matches. Deliberately does NOT
  flag the point-in-time "vX.Y.x, latest stable at pickup time" phrasing used by
  ADR-0019/0022/0023/0028/0029 — that's an intentional snapshot, not a live mirror,
  so leaving it unchanged after a patch bump is not drift. Reads yq scalars through
  a local `yqs()` helper (mirrors `tests/lib/yq.bash`, no bare `eval`/`eval-all`
  subcommand — the repo's yq sandbox is python-yq, which doesn't support `eval`
  as a subcommand at all).
- `make adr-chart-version-sync-check` target + wired into `make ci`'s recipe.
- `.github/workflows/ci.yml`: the identical `bash scripts/
  adr-chart-version-sync-check.sh` step, keeping `make ci` and CI in parity
  (enforced mechanically by the existing `ci-parity-check.sh` gate, which caught
  the initial one-sided addition immediately via its PostToolUse hook).
- `scripts/adr-chart-version-sync-hook.sh` — PostToolUse hook wired in
  `.claude/settings.json`, reacting to edits under `docs/decisions/` or `gitops/`
  (either side of the drift), so a future session gets an immediate nudge instead
  of waiting for CI.
- `tests/drift-detectors.bats`: four new assertions (passes on an in-sync fixture;
  fails on a drift fixture, asserting the mismatch message names both versions;
  ignores an ADR using the non-self-tracking phrasing; passes on the real repo's
  ADR-0020/ADR-0021, asserting both are named in the output) plus three new
  fixture trees under `tests/fixtures/adr-chart-version-sync/
  {in-sync,drift,no-self-tracking}/`.

Behavior-preserving: no existing check's pass/fail set changed; this only adds a
new, previously-nonexistent gate. Verified directly (ADR-0004) that the real
repo's `docs/decisions/adr-0020-*.md` and `adr-0021-*.md` currently match their
live gitops pins (`2.41.1` / `12.1.0`) before landing this — the guard passes
today and will fail the next time either drifts without an accompanying ADR edit.

`make ci` passes.

## PR

[#622](https://github.com/tooming/k8s-anywhere/pull/622)
