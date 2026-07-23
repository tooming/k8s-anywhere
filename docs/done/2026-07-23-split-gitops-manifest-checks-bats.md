# Split gitops-manifest-structural-correctness tests out of tests/drift-detectors.bats

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Eighth and final planned slice of the
`tests/drift-detectors.bats` split-down follow-up (prior slices:
[docs/done/2026-07-23-split-idle-issue-guard-bats.md](2026-07-23-split-idle-issue-guard-bats.md),
[docs/done/2026-07-23-split-mimir-readonly-root-bats.md](2026-07-23-split-mimir-readonly-root-bats.md),
[docs/done/2026-07-23-split-frozen-monolith-checks-bats.md](2026-07-23-split-frozen-monolith-checks-bats.md),
[docs/done/2026-07-23-split-yq-variant-checks-bats.md](2026-07-23-split-yq-variant-checks-bats.md),
[docs/done/2026-07-23-split-adr-sync-checks-bats.md](2026-07-23-split-adr-sync-checks-bats.md),
[docs/done/2026-07-23-split-ci-workflow-checks-bats.md](2026-07-23-split-ci-workflow-checks-bats.md),
[docs/done/2026-07-23-split-routines-checks-bats.md](2026-07-23-split-routines-checks-bats.md);
freeze that started this thread:
[docs/done/2026-07-23-freeze-drift-detectors-bats.md](2026-07-23-freeze-drift-detectors-bats.md)).

## What changed

Moved three sections (`helm-chart-pin-check`, `argocd-crd-ssa-check`,
`rollouts-plugin-list-check`; 8 `@test` blocks, 70 lines total) out of
`tests/drift-detectors.bats` into a new
`tests/drift-gitops-manifest-checks.bats` — a pure file move, no test logic
changed. Grouped as one PR because all three guard structural correctness
of live `gitops/` manifests (a resolvable Helm chart pin, ServerSideApply on
oversized-CRD Applications, Argo Rollouts plugin lists staying real YAML
lists) rather than any one component's own configuration.
`tests/drift-detectors.bats` shrinks from 243 to 173 lines. Regenerated
`tests/.drift-detectors-titles` via `make drift-detectors-tests-mark`.

This closes out the split-down thread: `tests/drift-detectors.bats` is now
173 lines (down from 662 at the start — a 74% reduction), holding only
`readme-check`, `lab-ui-check`, `roadmap-check`, `markdown-links-check`,
`git-fixture-isolation-check`, the O2 PSS completeness gate, and the
`drift-detectors-tests-check` guard's own self-tests. No further split is
planned in this run; a future run can pick up any of the remaining sections
if a genuine motivation arises, but the monolith-growth footgun is now
mechanically guarded either way.

## Why this is safe

Pure move: every `@test` title/body/assertion is byte-identical in its new
location. `bats tests/drift-gitops-manifest-checks.bats` in this sandbox
shows the same 6 pre-existing failures (out of 8) as every prior PR this
run — this sandbox's non-mikefarah `yq` (`helm-chart-pin-check` ×3,
`argocd-crd-ssa-check` ×2, `rollouts-plugin-list-check` ×1) — confirming the
move relocated the exact same behavior, nothing new broke. No script under
test was touched. `make ci` stays green — same pre-existing, environment-only
`not ok` failures as every prior PR this run, unrelated to this change.

## Scope discipline

Bounded to one coherent group of sections, per the janitor role's "small
enough to land green in one run" rule.

## PR

(filled in after PR creation)
