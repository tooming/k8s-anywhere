# upgrade(kyverno): 3.3.4 → 3.3.9

Routine upgrade-drafter sweep (executor STEP 6b fallback — the "Now / next" lane was
gated again this cycle, and this run's own architect-fallback sweep earlier today
found no new applicable CVE audit to open).

## What changed

`gitops/platform/kyverno.yaml`'s `targetRevision` bumped from `3.3.4` to `3.3.9` —
same-minor patch bump (chart `3.3.x` line unchanged; `appVersion` `v1.13.2` →
`v1.13.6`, same `1.13.x` line). No `valuesObject` changes.

## Why this version

Highest stable patch release in the currently-pinned `3.3.x` chart line, no major
or minor bump crossed. Verified via the actual commit range between the
`kyverno-chart-3.3.4` and `kyverno-chart-3.3.9` tags (`kyverno.github.io`'s
Helm repo index is proxy-blocked in this sandbox; used a direct git fetch of the
upstream `kyverno/kyverno` repo's tags instead) — 38 commits, bundling several real
CVE fixes: `kyverno/kyverno` CVE-2025-46569, CVE-2025-30204 (`golang-jwt/jwt/v5`),
CVE-2025-22869 (`golang.org/x/crypto`), and an earlier `golang-jwt/jwt/v4` CVE fix,
plus routine bug fixes. This is upgrade-drafter's highest-priority case
("a CVE-mentioning release > a patch > a minor").

## Restricted-PSA re-verification (ADR-0004)

RFC #483's `kyverno` namespace PSA `restricted` flip (2026-07-17) was verified
against the exact `kyverno-chart-3.3.4` tag's rendered `securityContext` defaults.
Since this bump changes the pinned tag, re-fetched `kyverno-chart-3.3.9`'s real
`values.yaml` fresh before bumping: all four controllers (admission, background,
cleanup, reports) still default to `runAsNonRoot: true`,
`allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`,
`readOnlyRootFilesystem: true`, `seccompProfile.type: RuntimeDefault` — identical
to what RFC #483 verified at `3.3.4`. No regression, no `valuesObject` override
needed. Updated the stale `3.3.4` citations in ADR-0017's per-namespace profile
table + a new dated Re-evaluation log entry, ADR-0019's per-namespace profile
table, and the `gitops/kyverno/namespace.yaml` comment to reflect the
re-verification (historical audit entries describing what was true in the
2026-07-17 flip were left untouched, per ADR-0004 — a new dated entry records
this bump instead of rewriting history).

Extended `tests/kyverno.bats` with two assertions: the new pin is present, and the
old pre-bump pin is absent (recurrence guard).

**ADR-0004 caveat:** this remote clusterless session cannot verify the admission
webhook stays healthy post-bump on a live cluster — same caveat every other chart
bump in this repo carries. **Rollback path:** revert `targetRevision` back to
`3.3.4` — ArgoCD self-heals.

`make ci` passes (same pre-existing sandbox-only failures unrelated to this
change, confirmed via `git stash` against unmodified `main`).

## PR

https://github.com/tooming/k8s-anywhere/pull/506
