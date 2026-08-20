# Dependency register: Harbor + Kiali currency/GHSA sweep

(CHARTER **Core Values** §"Everything as code" + general hardening; executor-fallback
upstream-currency sweep 2026-08-20, second pass this run — reached via
`executor.prompt.md` STEP 6b after the first pass's kube-state-metrics chart bump
(`auto/ksm-chart-8-4-0`, PR #1290, merged) still left the "Now / next" lane fully
gated (re-checked: issues #633/#1229 both re-read, no new comments since the prior
cycle). **No prerequisites — executor may pick up immediately.**

`docs/dependency-register.md`'s "Last reviewed" column is a manual, best-effort
snapshot with no mechanical drift guard (per the file's own "Keeping this in sync"
section). Its two oldest rows were **Harbor** (`2026-08-03`, 17 days stale relative to
today) and **Kiali** (`2026-08-04`, 16 days stale) — both citing only a chart-bump date,
not a real re-verification. Picked both as this cycle's angle: the oldest un-refreshed
rows in the table, same "sweep what's gone longest without a real check" logic this
session's earlier cycles already applied to Loki/Tempo/Alloy/node-exporter.

Verified directly (not assumed, ADR-0004):

- **Kiali** — `kiali/kiali`'s GitHub security-advisories page has zero published
  advisories at all. `kiali/helm-charts` tags confirm `v2.30.0` (Aug 3, 2026) is still
  the newest chart release — matches this repo's pin
  (`gitops/platform/kiali.yaml`'s `targetRevision: 2.30.0`) exactly. No bump needed.
- **Harbor** — `goharbor/harbor`'s security-advisories page lists two 2026 entries
  since the `1.19.2` chart bump: **GHSA-prh4-vhfh-24mj** (Moderate — LDAP
  `ldap_search_password`/OIDC `oidc_client_secret` logged unredacted in the audit
  log), affecting `>2.13.0,<2.14.3`, patched in `2.13.5`/`2.14.3`/`2.15.0`; and
  **GHSA-56j8-6qr5-cg75** (Low, CVE-2026-4404), which Harbor's own maintainers dispute
  as not a legitimate vulnerability ("Awaiting Analysis", no patched version listed).
  This repo's Harbor chart pin (`1.19.2`) bundles `appVersion: 2.15.2`
  (`gitops/platform/harbor.yaml`, confirmed against the chart's own `Chart.yaml` at
  the `v1.19.2` tag) — past GHSA-prh4-vhfh-24mj's `2.15.0` patched floor, and the
  disputed low-severity CVE has no actionable patched version regardless.
  `goharbor/harbor-helm` tags confirm `v1.19.2` (Aug 3, 2026) is still the newest
  chart release — matches this repo's pin exactly. No bump needed.

Updated `docs/dependency-register.md`'s Harbor and Kiali rows' "Last reviewed" cells
with today's date and the real findings above (each mirroring this table's existing
"GHSA sweep: ..." citation convention used by most other rows, e.g. Argo Rollouts,
Trivy Operator, Cilium). No `gitops/` manifest change — neither component needed a
version bump, so no `make ci` gitops-touching check is exercised beyond the standard
markdown-link/readme/drift checks, all confirmed green locally before push.

**ADR-0004 caveat:** none beyond the standing one already on every register row — this
is a documentation-accuracy fix, not a live-cluster claim.

## PR

https://github.com/tooming/k8s-anywhere/pull/1291
