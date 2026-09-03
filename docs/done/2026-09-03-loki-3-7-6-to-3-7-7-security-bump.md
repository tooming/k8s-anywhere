# Bump Loki image tag `3.7.6` → `3.7.7` (security-relevant dependency bumps)

`grafana/loki`'s register row (`docs/dependency-register.md`) was the oldest-reviewed
of all 33 rows as of this cycle (last reviewed 2026-08-06), and ADR-0006's own flip
condition for Loki ("revisit when a new advisory/fix range names a version at or
above `3.7.6` as affected") was due for a re-check. A planner-fallback currency sweep
picked it up specifically for that reason.

Verified directly (not assumed, ADR-0004): GitHub's tags list for `grafana/loki`
confirms `v3.7.7` (published 2026-08-27) is the newest tag on the `3.7.x` line pinned
here — no major/minor jump, no newer `3.7.x` patch exists. `v3.7.7`'s own release
notes list three security-relevant dependency updates ("for security purposes" each):
`containerd` module bumped to `v2.2.5`, `etcd` client package bumped to `v3.6.14`,
`golang.org/x/mod` bumped to `v0.40.0` — plus a functional flag (ignore missing
chunks during deletion) and a storage optimization (pre-computed SHA-256 hashes to
avoid aws-chunked encoding on `PutObject`). Docker Hub's public tag API confirms
`grafana/loki:3.7.7` is a real, published multi-arch manifest (amd64/arm64/armv7,
pushed 2026-08-27T20:15:44Z).

## What changed

- `gitops/observability/loki/deployment.yaml`: `image: grafana/loki:3.7.6` →
  `grafana/loki:3.7.7`.
- `tests/observability-loki.bats`: assert `3.7.7` present, `3.7.6` absent
  (recurrence guard, same pattern as every prior Loki bump).
- `docs/decisions/adr-0006-grafana-native-git-sync.md`: new Re-evaluation log entry
  documenting the trigger, verification, decision, ADR-0004 caveat, and next flip
  condition — same shape as every prior entry in this file.
- `docs/dependency-register.md`: Loki's row updated to `2026-09-03` with the real
  bump summary. Grafana's row (also cited under ADR-0006) was collaterally bumped to
  `2026-09-03` too, honestly worded — `scripts/dependency-register-check.sh`'s
  `###`-heading shape compares a row against its cited ADR's *global* latest
  Re-evaluation entry, and can't distinguish which of ADR-0006's several components
  (Grafana/Loki/Tempo) a given heading is about (a documented limitation in the
  script's own header comment). Grafana's own last real currency check remains
  2026-08-19, unaffected by this cycle's work — the register row's prose says so
  explicitly rather than implying a fresh Grafana check happened.

## ADR-0004 caveat

Same as every prior Loki bump: this remote, clusterless session verified the
release-notes and published-image facts directly, but cannot verify Loki starts
cleanly and continues ingesting logs post-bump on a live cluster. Rollback is a
one-line revert of the `image:` tag; no data loss either way since Loki's log storage
lives in Garage S3, untouched by an image-tag change.

`make ci` passes green (lint/readme-check/lab-ui-check/all drift detectors including
`dependency-register-check.sh` — bats/kustomize/terraform tools aren't installed in
this clusterless session; the full suite runs in GitHub Actions).

## PR

https://github.com/tooming/k8s-anywhere/pull/1383
