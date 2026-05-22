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
