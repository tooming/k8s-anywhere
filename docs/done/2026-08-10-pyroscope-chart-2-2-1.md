# Bump Pyroscope chart `2.2.0` → `2.2.1` (upstream security release)

(CHARTER **Core Values** §"Everything as code" + general hardening; executor-fallback
currency sweep 2026-08-10, second pass this run, reached via `executor.prompt.md`
STEP 6b — the same three standing Now/next items remain gated on unconfirmed
maintainer-confirmation issues #631/#633/#1034 (re-checked this cycle, #1034
unchanged since 2026-08-07). This cycle's fresh angle (continuing the prior cycle's
`git ls-remote --tags` sweep to charts not yet checked this run): cert-manager, keda,
vault, ack-s3, kargo, envoy-gateway, node-exporter, and alloy all confirmed current
against their real chart-publishing repos; Pyroscope's chart (published from
`grafana/pyroscope`'s own `operations/pyroscope/helm/pyroscope`, not the
`grafana/helm-charts` monorepo — the source moved out of that repo, though release
tags still land there too) turned up one minor version behind. **No prerequisites —
executor may pick up immediately.**) Verified directly (not assumed, ADR-0004):
`git ls-remote --tags grafana/pyroscope` shows `pyroscope-2.2.1` as the newest tag,
one release past the pinned `2.2.0`; both `version` and `appVersion` move together in
`Chart.yaml`. A full source diff (`git diff pyroscope-2.2.0 pyroscope-2.2.1 --
operations/pyroscope/helm/pyroscope/`) shows `values.yaml` and every template
byte-identical — only version-label churn in the rendered manifests (`helm.sh/chart`,
`app.kubernetes.io/version`). The upstream chart-bump PR (grafana/pyroscope#5474)
states this explicitly: "updates the Helm chart to align with the v2.2.1 **security
release** of Pyroscope." The v2.2.1 app release fixes: `github.com/getkin/kin-openapi`
(**GHSA-r277-6w6q-xmqw**, critical), `google.golang.org/grpc` (**GHSA-hrxh-6v49-42gf**),
`golang.org/x/text` (**CVE-2026-56852**), `golang.org/x/net` (**CVE-2026-46600**), plus
a `klauspost/compress` bump and UI-dependency fixes (tar/js-yaml/brace-expansion/
ip-address) — well past this repo's "ships with a real security fix" bar. This repo's
existing `readOnlyRootFilesystem: true` verification (checked against the pinned chart
source, cited inline in `observability-pyroscope.yaml`) carries forward unchanged
since the template is byte-identical.

Bump `gitops/platform/observability-pyroscope.yaml`'s `targetRevision: 2.2.0` →
`2.2.1`; update its inline comment citing the verified chart tag. New
`tests/observability-pyroscope.bats` (clusterless structural, mirrors
`tests/observability-loki.bats`'s per-scope pattern): asserts the Application pins
`targetRevision: 2.2.1`; asserts it does NOT pin the stale `2.2.0` (recurrence guard).
Update `docs/decisions/context.md`'s "Pyroscope (chart 2.2.0" citation to `2.2.1`
(required — `make context-doc-version-sync-check` mechanically enforces this). Update
`docs/dependency-register.md`'s Pyroscope row "Last reviewed" cell. Add a new dated
entry to [ADR-0034](../decisions/adr-0034-lgtmp-observability-stack.md)'s
`## Re-evaluation log` (its first, alongside updating its own "What's actually
running" table's Pyroscope row to `2.2.1`) documenting the security findings above —
**Keep**, no reason to reconsider the component itself. No `docs/dependency-tree.md`
update needed — it doesn't cite Pyroscope's specific chart version (checked directly).
`make ci` must pass. PR body must document the security findings above and the
ADR-0004 caveat that this remote clusterless session cannot verify Pyroscope starts
cleanly and continues ingesting profiles post-bump on a live cluster — call out the
rollback path (revert `targetRevision`; ArgoCD re-syncs the prior chart version on its
next reconciliation; Pyroscope's profile data lives on Garage S3 + its PVC, untouched
by a chart-version revert). `docs/done/` entry required.
(auto/pyroscope-chart-2-2-1)

## PR

https://github.com/tooming/k8s-anywhere/pull/1082
