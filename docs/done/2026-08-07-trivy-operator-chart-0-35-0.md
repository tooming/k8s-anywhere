# Bump Trivy Operator chart `0.34.0` → `0.35.0` (appVersion `0.32.0` → `0.33.0`, bundled Trivy scanner `0.72.0` → `0.73.0`)

(CHARTER **Objective O1** + **Core Values** §"Everything as code" + general
hardening; executor-fallback currency sweep 2026-08-07, reached via
`executor.prompt.md` STEP 6b after Now/next's three standing items were
re-checked and found still gated (unchanged) on unconfirmed
maintainer-confirmation issues #631/#633, and this same run's first cycle
(`auto/argocd-chart-10-3-0`) already claimed the ArgoCD chart gap a prior
planner-fallback cycle surfaced. This cycle's fresh angle:
`docs/dependency-register.md`'s per-component "Last reviewed" column flagged
Trivy Operator's 2026-07-28 entry as the most stale among the four CHARTER
O1 next-wave components. **No prerequisites — executor may pick up
immediately.**)

## Verification (ADR-0004 — verified directly, not assumed)

`aquasecurity/helm-charts`' `main` branch no longer carries chart source (the
repo migrated to a chart-releaser flow that publishes packaged `.tgz` release
assets + a `gh-pages` Helm-repo index instead of per-tag directories) —
verification here downloaded and `diff -ru`'d the two real release tarballs
(`trivy-operator-0.34.0.tgz`/`trivy-operator-0.35.0.tgz`) directly rather than
a git-tag diff. The `gh-pages` index shows `trivy-operator-0.35.0` published
2026-08-06T03:12:49Z, one release past the pinned `0.34.0`.

The tarball diff touches exactly: `Chart.yaml`'s `version`/`appVersion`
fields (`0.34.0`→`0.35.0`, `appVersion` `0.32.0`→`0.33.0`), the generated
`README.md` badges/table for the same, and the bundled `trivy.image.tag`
default (`0.72.0`→`0.73.0`, in both `values.yaml` and the README row) — plus
the same version-label bump repeated across five `templates/specs/*.yaml`
compliance-scan CronJob manifests (label only, not behavior). No other
`values.yaml` key changed shape — every key this lab's `valuesObject` sets
(`operator.*`, `trivy.resources`/`storageClassName`/`storageSize`,
`nodeCollector.*`) is present and unchanged.

A real clone's `git log v0.32.0..v0.33.0` (trivy-operator app repo) shows 4
commits: 2 routine dependency bumps (`golang.org/x/text` 0.38.0→0.39.0, the
`k8s.io/*` client group 0.36.2→0.36.3) and the `trivy` scanner version bump
itself — no operator-side feature/fix commit in this range. The bundled
Trivy scanner bump (`v0.72.0`→`v0.73.0`, `aquasecurity/trivy`) carries two
real detection-accuracy fixes: `fix(vuln): don't skip packages covered by a
driver's own advisory feed` (#10980) and `fix(vex): reject non-local VEX
repository names` (#10987) — both correctness fixes to the scanner's own
vulnerability-detection path, the same "ships with a real fix" bar this
repo's other non-CVE currency bumps (e.g. Loki's ingester flush-race fix)
use.

Does not affect ADR-0022's existing March-2026 Trivy supply-chain compromise
finding (`v0.69.4` is still the only affected tag; `0.73.0` postdates it by
many releases) — this bump only moves the citation the compromise finding
references, noted in the ADR's new re-evaluation log entry.

## What changed

- `gitops/platform/trivy-operator.yaml`'s `targetRevision: 0.34.0` →
  `0.35.0`.
- `tests/trivy-operator.bats`: pin assertion updated to `0.35.0`, plus a new
  "does not pin the stale `0.34.0` chart" recurrence guard.
- `docs/dependency-tree.md`'s Trivy Operator citation (`v0.34.0`→`v0.35.0`).
- `docs/dependency-register.md`'s Trivy Operator row "Last reviewed" cell.
- [ADR-0022](../decisions/adr-0022-trivy-operator-supply-chain.md): new dated
  re-evaluation log entry.

No `context.md` update needed — it doesn't cite this chart's specific
version (checked directly).

## ADR-0004 caveat

This remote, clusterless session cannot verify the operator reconciles
cleanly and continues scanning post-bump on a live cluster.

## Rollback path

Revert `targetRevision`; ArgoCD re-syncs the prior chart version on the next
reconciliation. The operator is stateless apart from its ephemeral vuln-DB
cache PVC, so a rollback recovers immediately with no data loss.

## PR

https://github.com/tooming/k8s-anywhere/pull/1057
