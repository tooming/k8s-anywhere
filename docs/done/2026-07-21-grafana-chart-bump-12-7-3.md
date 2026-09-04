# Bump Grafana chart `12.7.2` → `12.7.3`

Upgrade-drafter fallback (executor routine, STEP 6b — a second, later-cycle
invocation of this lens in the same run; the first invocation this session
landed the Pyroscope patch bump, #650). ROADMAP `Now / next` remained fully
gated across five consecutive cycles today (standing maintainer-confirmation
issues #631/#632/#633, all still open, zero comments) with every other
fallback lens re-checked clean, so a second upgrade-drafter pass picked up
the highest-priority remaining candidate from this session's earlier chart
sweep (`docs/done/2026-07-21-pyroscope-chart-bump-2-1-2.md` lists the full
findings): grafana's patch bump outranks alloy's minor bump per the
CVE > patch > minor priority order.

## What changed

`gitops/platform/observability-grafana.yaml`'s `targetRevision` bumped
`12.7.2` → `12.7.3` (chart-only patch, released 2026-07-21). Confirmed via
the real `Chart.yaml` at the `grafana-12.7.3` tag: chart `version: 12.7.3`,
default `appVersion: 13.1.1` — **irrelevant to what actually runs**, since
this repo's `valuesObject.image.tag` already pins the running binary at
`"13.0.3"` (ADR-0006's Pure-Git Git Sync provider requirement + the 13.0.0
unified-storage migration bug history), independent of the chart's own
default. The chart's GitHub release notes for `grafana-12.7.3` state the
only change is a Renovate-bot bundled default image-tag bump — no CVE, no
breaking change.

Verified the security-critical `securityContext`/`containerSecurityContext`
key paths this repo's `valuesObject` depends on are unchanged in the new
chart tag's `templates/_pod.tpl` (still `.Values.securityContext` at
pod-level, `.Values.containerSecurityContext` at container-level — matches
this repo's existing keys exactly). Updated the in-file comment documenting
the `readOnlyRootFilesystem` write-path analysis to note the 12.7.2→12.7.3
bump changed only the chart's default bundled image tag (per its own
release notes), not `templates/_pod.tpl`, so that analysis still holds
unchanged. Left the migration-specific historical comment (documenting the
10.5.15→12.7.2 chart-source migration byte-diff) untouched — it correctly
describes a past, dated verification event, not current state.

Did not touch: `ROADMAP.md`'s and `docs/done/`'s prior checked-off items
referencing "`12.7.2`" (they're dated historical records of past PRs, not
living docs) or ADR-0020's re-evaluation-log parenthetical mention of
grafana's pin (also a dated audit-log entry).

## Why this version

Highest stable release, no major bump, no pinning ADR (ADR-0006 pins the
*image tag*, not the chart `targetRevision` — confirmed no self-tracking
ADR chart-version note references this chart's `targetRevision`, unlike
ADR-0020/ADR-0021 which do). No CVE mentioned in the release.

## Upstream notes

- Release: https://github.com/grafana-community/helm-charts/releases/tag/grafana-12.7.3
- Chart.yaml at the tag: https://raw.githubusercontent.com/grafana-community/helm-charts/grafana-12.7.3/charts/grafana/Chart.yaml
- Template verified: https://raw.githubusercontent.com/grafana-community/helm-charts/grafana-12.7.3/charts/grafana/templates/_pod.tpl

## What `make ci` saw

Green (bats/kustomize/kubeconform/terraform/shellcheck/yamllint aren't
installed in this remote sandbox and gracefully skip; GitHub Actions is the
authoritative gate).

## PR

https://github.com/tooming/k8s-anywhere/pull/653
