# Inkless kafka-exporter sidecar — documented in ADR-0015, currency-checked clean

`danielqsj/kafka-exporter:v1.9.0` has run as a Prometheus-metrics sidecar in
`gitops/inkless/inkless-statefulset.yaml` since Inkless first landed, but had
zero mention anywhere in ADR-0015 — the same class of gap ADR-0038/ADR-0039
closed for moto/ACK/KRO/s3manager elsewhere this run, here small enough to
close as a section addition to the existing governing ADR rather than a new
one (kafka-exporter is Inkless's own observability sidecar, not an
independent architectural choice).

## What was checked

Directly against live sources (ADR-0004):

- Docker Hub's tags API confirms `v1.9.0` (2025-02-17) is still the newest
  real version tag (`latest` was re-pushed 2026-04-13 but carries no newer
  content).
- Zero published GHSA advisories exist for `danielqsj/kafka_exporter`.

## Decision: kept at `v1.9.0`

No currency or security gap — this cycle's work is documentation only.

## What changed

- `docs/decisions/adr-0015-inkless-diskless-kafka.md`: new "Observability —
  kafka-exporter sidecar" section (mirroring how ADR-0018 documents Valkey's
  `redis_exporter`), plus a new Re-evaluation log entry.
- `docs/dependency-register.md`: Inkless row's "Last reviewed" prose updated
  to mention this finding.

No `gitops/` change. `make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1401
