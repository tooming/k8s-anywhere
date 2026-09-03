# Author ADR-0038 — moto + ACK (S3) + KRO for the cloud-control-plane demo pattern (retroactive record); bump moto `5.2.2` → `5.2.3`

moto, ACK (S3 controller), and KRO have been real, live, always-on (KRO
currently suspended) components since early in this repo's life — each with
its own ArgoCD `Application`, PSA `restricted` namespace, default-deny
NetworkPolicy, a real-metric Grafana dashboard
(`grafana/dashboards/lab-cloud-control-plane.json`), and dedicated bats
coverage — yet none of the 37 ADRs prior to this one named them as its
subject, and none had a `docs/dependency-register.md` row. ACK-S3's real
version-bump history instead lived only as inline YAML comments in
`gitops/platform/ack-s3.yaml`, the same shape ADR-0037 found and fixed for
Vault.

## What changed

- **New `docs/decisions/adr-0038-ack-kro-moto-cloud-control-plane.md`**:
  retroactive governance record covering all three components — their roles,
  chart/image pins, security posture, the documented ACK `ReadOne` panic
  limitation, KRO's 2026-08-24 suspension (and why), observability, test
  coverage, and a Re-evaluation log migrating ACK-S3's two prior inline
  version-bump entries plus a new combined currency+GHSA sweep across all
  three.
- **`gitops/moto/deployment.yaml`**: image bumped `motoserver/moto:5.2.2` →
  `5.2.3` (confirmed real via Docker Hub's tags API, `last_updated:
  2026-08-22`; routine patch, no CVE, no published GHSA advisories exist for
  `getmoto/moto` at all).
- **`gitops/platform/ack-s3.yaml`**: removed the inline version-history
  comment block (migrated to ADR-0038), replaced with a short pointer —
  same cleanup ADR-0037 did for `vault.yaml`.
- **`docs/decisions/README.md`**: added the ADR-0038 index entry.
- **`docs/dependency-register.md`**: added three new rows (moto, ACK S3
  controller, KRO); fixed the Scope note's arithmetic (37→38 ADRs, 34→37
  rows).

ACK S3 controller (`1.11.0`) and KRO (`0.9.3`) were both reconfirmed already
current — no upstream release exists past either pin (verified directly:
ACK's next-patch `Chart.yaml` 404s; KRO's real GitHub releases list still
shows `v0.9.3` as newest). Also found, incidentally: the KRO project has
moved GitHub orgs to `kubernetes-sigs/kro` (a real Kubernetes SIG Cloud
Provider subproject now) — noted in the ADR, not action-requiring since the
lab's `ghcr.io/kro-run/kro` chart-pull path is a separate system that still
resolves.

## Why this is real (not manufactured) ARCHITECT-fallback work

Found via this run's coverage/hardening sweep (ROADMAP rule #9's fallback
chain) after the "Now / next" lane was re-confirmed fully gated and
PLANNER/ARCHITECT/TRIAGER all came up empty. Same shape as the ADR-0036/
ADR-0037 gaps closed earlier this run — a real, already-implemented,
already-live mechanism with zero governance record, not a new technical
choice. No binding ADR is contradicted or superseded.

`make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1399
