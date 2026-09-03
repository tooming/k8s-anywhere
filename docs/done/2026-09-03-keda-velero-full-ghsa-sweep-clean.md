# KEDA + Velero full GHSA sweep — both pins confirmed clean

Extending this run's "check every published advisory directly" technique
(Envoy Gateway, Cilium, ArgoCD, cert-manager) to KEDA and Velero — both
small enough advisory sets to sweep exhaustively in one PR.

## Verification

Confirmed directly (not assumed, ADR-0004):

### KEDA — `github.com/kedacore/keda/security/advisories` (3 total)

| Advisory | Severity | Affected | Patched | Status |
|---|---|---|---|---|
| GHSA-6w3m-4hhp-775q | Moderate | (already tracked) | `2.20` | tracked |
| GHSA-c4p6-qg4m-9jmr | High | (already tracked) | `2.17.3`/`2.18.3`/`2.19.0`+ | tracked |
| GHSA-w92x-gx4w-j5f2 | Low | KEDA's own `pr-e2e.yml` CI workflow, v2.11 | `2.11.2` | **new — not applicable** |

`GHSA-w92x-gx4w-j5f2` is a command-injection bug in KEDA's own GitHub
Actions CI workflow file, triggerable via a crafted PR title/branch name
against KEDA's upstream repo. It does not affect the `keda` or
`keda-metrics-apiserver` container images this lab deploys, at any
version. Current pin `2.20.2` is unaffected regardless.

### Velero — `github.com/vmware-tanzu/velero/security/advisories` (2 total)

| Advisory | CVE | Severity | Affected | Patched |
|---|---|---|---|---|
| GHSA-j2g6-362q-6qc6 | (already tracked) | Moderate | `<1.18.1` | `1.18.1` |
| GHSA-72xg-3mcq-52v4 | CVE-2020-3996 | Moderate | `0.*`/`1.*` before `1.4.3`/`1.5.2` | `1.4.3`, `1.5.2` |

`GHSA-72xg-3mcq-52v4` (PV/PVC binding issue on restore) had not been
explicitly checked before. Current pin (chart `12.1.0`, appVersion
`1.18.1`) is many majors past both floors.

## Decision: keep both pins

No security-driven reason to bump either. All 5 advisories across both
projects are now accounted for.

## What changed

- `docs/decisions/adr-0029-keda-event-driven-autoscaling.md`: new
  Re-evaluation log entry.
- `docs/decisions/adr-0021-velero-backup-restore.md`: new Re-evaluation
  log entry (matching that ADR's own bullet-style, newest-first
  convention).
- `docs/dependency-register.md`: KEDA and Velero rows updated.

No code change. `make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1396
