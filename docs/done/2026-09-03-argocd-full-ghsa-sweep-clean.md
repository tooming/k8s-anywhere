# ArgoCD full GHSA sweep — `v3.5.2` confirmed security-clean

Extending this run's "full advisory listing, not just currency" technique (Envoy
Gateway, Cilium) to ArgoCD — this lab's actual GitOps deployment mechanism and,
per `docs/dependency-exit-runbooks.md`, its single largest possible dependency
exit. All 8 published `argoproj/argo-cd` GitHub security advisories were checked
directly.

## Verification

Confirmed directly (not assumed, ADR-0004):

| Advisory | CVE | Severity | Affected (tops out at) | Patched |
|---|---|---|---|---|
| GHSA-3v3m-wc6v-x4x3 | CVE-2026-42880 | Critical | `3.2.0`-`3.3.8` | `3.2.11`, `3.3.9` |
| GHSA-rg3g-4rw9-gqrp | CVE-2026-45737 | Moderate | `3.2.0`-`3.2.11`, `3.3.9`, `3.4.1` | `3.2.12`, `3.3.10`, `3.4.2` |
| GHSA-h98r-wv3h-fr38 | CVE-2026-45738 | High | `<3.0.0` | `3.2.12`, `3.3.10`, `3.4.2` |
| GHSA-786q-9hcg-v9ff | CVE-2025-55190 | Critical | `≥2.2.0-rc1` up to | `3.1.2`, `3.0.14`, `2.14.16`, `2.13.9` |
| GHSA-gpx4-37g2-c8pv | CVE-2025-59538 | High | up to `3.2.0-rc1`, `3.1.6`, `3.0.17` | `3.2.0-rc2`, `3.1.8`, `3.0.19` |
| GHSA-f9gq-prrc-hrhc | CVE-2025-59531 | High | up to `3.2.0-rc1`, `3.1.7`, `3.0.18` | `3.2.0-rc2`, `3.1.8`, `3.0.19` |
| GHSA-wp4p-9pxh-cgx2 | CVE-2025-59537 | High | up to `3.2.0-rc1`, `3.1.7`, `3.0.18` | `3.2.0-rc2`, `3.1.8`, `3.0.19` |
| GHSA-g88p-r42r-ppp9 | CVE-2025-55191 | Moderate | up to `3.2.0-rc1`, `3.1.7`, `3.0.18` | `3.2.0-rc2`, `3.1.8`, `3.0.19` |

Every affected range tops out at `3.4.2` or lower — this lab's current pin
(appVersion `v3.5.2`) is past every published floor, including the highest
severity (Critical, GHSA-3v3m-wc6v-x4x3 — a `ServerSideDiff`-endpoint secret
extraction most exploitable when an `Application` sets
`argocd.argoproj.io/compare-options: IncludeMutationWebhook=true`; this lab's
own `Application` manifests don't set that annotation anywhere, though the pin
is past the fix regardless).

## Decision: no change needed

The current pin is already secure against every published advisory. This
complements the chart-currency check done earlier this run (chart `10.5.0` →
`10.7.0` exists but is template-only, same appVersion, judged not worth the risk
to this component for zero functional gain) — this sweep confirms that decision
wasn't hiding an unpatched security gap.

## What changed

`docs/dependency-register.md`: ArgoCD row updated. ArgoCD has no dedicated ADR
with its own Re-evaluation log (its register row cites ADR-0001, the broad
GitOps-vs-Terraform decision, which has no such section) — so the sweep result
is recorded in the register row itself, same shape and detail as this run's
other GHSA-sweep entries.

No code change. `make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1393
