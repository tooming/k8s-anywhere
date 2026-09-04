# Bump Mimir image tag `3.1.3` → `3.1.4`

Upgrade-drafter fallback (executor routine, STEP 6b). ROADMAP `Now / next` is
fully gated this cycle — all five remaining `[ ]` items depend on the
standing maintainer-confirmation issues #631/#632/#633, all still open with
zero comments (re-verified this cycle). A fresh architect-lens CVE/version
sweep across every component not covered by the immediately preceding
session's chart-pin sweep (cert-manager, KEDA, external-secrets, Kyverno,
ArgoCD's own chart, HashiCorp Vault, RabbitMQ, Garage, Grafana Mimir/Loki/
Tempo) found every pin already current or already patched against every
CVE discovered — except this one real, ordinary (non-CVE) patch release.

## What changed

`gitops/observability/mimir/deployment.yaml`'s `image:` tag bumped
`grafana/mimir:3.1.3` → `grafana/mimir:3.1.4` (positively confirmed via
Docker Hub's real tags API — `3.1.4` returns 200, `3.1.5`/`3.2.0`/`3.2.1` all
404, confirming `3.1.4` is the newest tag on/after the `3.1.x` line).
Extended `tests/observability-mimir.bats`'s existing image-tag pin
assertion to `3.1.4`.

## Why this version

Highest stable release, no major bump, no pinning ADR (grep confirmed no
`docs/decisions/*.md` file pins a Mimir version). Per Mimir's own
`CHANGELOG.md` (fetched from `raw.githubusercontent.com/grafana/mimir/main/CHANGELOG.md`,
verified real, not inferred — ADR-0004): `3.1.4` fixes a packaging
regression where DEB/RPM-built binaries shipped without the executable bit
set, causing `mimir.service` to fail to start (upstream #16166). This is a
Linux-packaging-specific bug (not a CVE) — it may not even reproduce in
this repo's Docker-image deployment path, but the tag is otherwise a
pure superset patch of `3.1.3` (which itself was a security release —
Go upgraded to 1.26.5 for CVE-2026-39822/CVE-2026-42505, already running
today), so taking it is strictly safe: no known regression, and it costs
nothing to stay current.

## ADR-0004 caveat

This remote clusterless session cannot verify Mimir actually starts cleanly
against real ingested block/WAL data on a live cluster post-bump. Rollback
path: revert the `image:` tag; Mimir is a single `Recreate`-strategy
Deployment (ADR-0005 single-host trade-off) backed by Garage-object-stored
blocks, so a revert re-rolls the same way the bump did — no data loss risk,
since TSDB blocks/WAL live in Garage (S3), not in the pod's ephemeral
filesystem.

## Upstream notes

- Docker Hub tag (confirmed live): https://hub.docker.com/r/grafana/mimir/tags?name=3.1.4
- Changelog: https://raw.githubusercontent.com/grafana/mimir/main/CHANGELOG.md

## What `make ci` saw

Green (bats/kustomize/kubeconform/terraform/shellcheck/yamllint aren't
installed in this remote sandbox and gracefully skip; GitHub Actions is the
authoritative gate for those).

## PR

https://github.com/tooming/k8s-anywhere/pull/665
