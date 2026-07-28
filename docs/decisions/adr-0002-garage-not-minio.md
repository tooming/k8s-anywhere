# ADR-0002 — Garage for S3-compatible storage (not MinIO)

**Decision.** Use **Garage** as the in-cluster S3-compatible object store. Do NOT
use MinIO.

**Why.** MinIO gutted its open-source offering (removed console features,
community backlash) around 2025 — considered "dead" for this purpose. Garage is a
lightweight, actively-maintained Rust S3 store. SeaweedFS is an acceptable
fallback; Rook-Ceph RGW is too heavy for a 16 GB lab.

**Use.** Backs Mimir (blocks/ruler) and Loki; will receive Longhorn backups if
Longhorn is ever added. Distinct from moto's S3 (moto = AWS-API/IaC learning;
Garage = real workload storage). Bootstrap (layout/key/buckets) is imperative via
the `garage` CLI — see `scripts/garage-bootstrap.sh`.

**Status.** Adopted. Deployed in `storage` ns; S3 verified.

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-28 — `v2.3.0` pin kept, still current (audit #776)

**Trigger.** First re-evaluation of this ADR's own audit trail (Garage's
currency was informally checked in a prior run's
`docs/backlog/2026-07-27-action-needed-argo-rollouts-eso-garage-sweep.md`
note, but never recorded against this ADR).

**Decision: Keep.** Verified directly against `Deuxfleurs/garage`'s real
release history: `v2.3.0` (released 2026-04-16, this lab's pin in
`gitops/storage/garage/statefulset.yaml`) is still the newest stable release —
no newer tag exists. No CVE found against Garage in any version. **Flip
condition:** a new Garage stable release ships with a security fix, or a CVE
is disclosed against `v2.3.0` specifically.
