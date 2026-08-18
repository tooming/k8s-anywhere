# Fix ADR-0034's stale Tempo image-pin table row + extend adr-image-pin-sync-check.sh to guard it

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's "every bugfix must prevent
recurrence" — janitor-fallback cleanup, `executor.prompt.md` STEP 6b, second cycle this
run, reached after PLANNER/ARCHITECT found nothing new (zero ungroomed issues, zero
un-RFC'd 🟡 items, zero `docs/roadmap/incoming/` files, this ISO week's industry digest
already fresh) and UPGRADE-DRAFTER's one-PR-per-run cap was already spent this run
(`upgrade/argocd-10.3.3-to-10.4.0`, PR #1221). DOC-DRIFT-AUTHOR and TRIAGER fallbacks
were checked next and found nothing in their own scope (`make ci`'s readme-check/
lab-ui-check/dependency-tree drift signals all clean; both open issues already
correctly labeled) — this finding needs an ADR edit, which is explicitly out of
DOC-DRIFT-AUTHOR's scope ("Don't touch any of: ADRs... that's the architect/executor's
lane"), landing it here as a JANITOR-shaped mechanical-guard cleanup instead.

## What was found

`docs/decisions/adr-0034-lgtmp-observability-stack.md`'s own "What's actually running"
table (its Tempo row) still cited the image tag as `2.10.7`, but the live pin in
`gitops/observability/tempo/deployment.yaml` has been `2.10.8` since 2026-08-13 — a
real security fix (Go 1.26.5 stdlib CVEs plus grpc/otel/x-net/x-text/compress
`[security]` dependency bumps), already correctly recorded in
[ADR-0006](../decisions/adr-0006-grafana-native-git-sync.md)'s own Re-evaluation log the
same day. The table cell simply wasn't updated when that bump landed.

Verified directly (not assumed, ADR-0004): `grep -n "image:"
gitops/observability/tempo/deployment.yaml` shows `grafana/tempo:2.10.8`; ADR-0006's
Re-evaluation log's 2026-08-13 entry documents the `2.10.7` → `2.10.8` bump and its CVE
rationale in full.

Root cause: `scripts/adr-chart-version-sync-check.sh` (`make ci`'s drift gate) already
guards ADR-0034's other table rows (Pyroscope/Alloy/KSM/node-exporter) against exactly
this class of drift, but only for the `` `gitops/x.yaml`, `targetRevision: Y` `` cell
shape — Tempo's row uses a different self-tracking shape (`` `gitops/<dir>` `` +
`` `image: <name>:<tag>` ``, a raw manifest image pin, not a chart's `targetRevision`),
which no check covered. This is the same self-tracking-note-can-silently-drift failure
mode ADR-0020/0021/0023/ADR-0034's other rows already proved happens (see those ADRs'
own Re-evaluation logs and `adr-chart-version-sync-check.sh`'s header comment) — just in
a shape with zero mechanical coverage until now.

## Fix

Corrected `adr-0034-lgtmp-observability-stack.md`'s Tempo table cell to `2.10.8` and
added a Re-evaluation log entry documenting the correction (no component
reconsidered — this is a doc-only fix, not a new Tempo finding).

**Mechanical guard** (CLAUDE.md's "every bugfix must prevent recurrence"): extended
`scripts/adr-image-pin-sync-check.sh` (which already guards the "pinned official
`<image>:<tag>`" Decision-prose phrasing used by ADR-0009/ADR-0018) with a second
self-tracking shape — a table row citing a `` `gitops/<dir>` `` raw-manifest directory
alongside the `` `image: <name>:<tag>` `` it pins directly. Mirrors
`adr-chart-version-sync-check.sh`'s existing table-row shape for `targetRevision`, just
for a raw image pin instead of a chart version. No hardcoded component list — discovers
any ADR table row using the same convention automatically, so a future component added
to ADR-0034 (or any other ADR) in this same shape is covered without a code change.

Added bats coverage in `tests/drift-adr-sync-checks.bats` (new fixtures under
`tests/fixtures/adr-image-pin-sync/table-{in-sync,table-drift}/`, mirroring the existing
fixture-pair convention): a passing case, a drift-detection case, and a real-repo
assertion that ADR-0034's Tempo row now matches its live pin.

`make ci` passes: full local suite green (bats installed this session via `apt-get`);
the new `== ADR image-pin sync ==` gate output shows
`adr-0034-lgtmp-observability-stack.md: image-pin table row (grafana/tempo:2.10.8)
matches gitops/observability/tempo's live image tag`, confirming the fix and the new
guard both work together. Before the fix, the extended check correctly reproduced the
drift (`bad` output citing the exact `2.10.7` vs `2.10.8` mismatch) — verified live
before applying the ADR text fix, not assumed.

Behavior-preserving: no runtime/manifest change, no test outcome changed beyond the
newly-added guard assertions. ADR-0004 caveat: this remote clusterless session can't
verify Tempo is actually healthy on a live cluster post-2.10.8 (that bump already
shipped and merged in a prior PR, verified only by reading its own record here) — this
PR is a documentation-and-guard-only diff.

## PR

https://github.com/tooming/k8s-anywhere/pull/1222
