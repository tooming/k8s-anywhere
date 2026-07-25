# [Action needed] Now/next still gated; direct Docker Hub image-tag sweep found no drift

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on the
standing maintainer-confirmation issues #631/#632/#633 — re-verified this cycle
(fifth cycle of 2026-07-25, a new scheduled run): all three still open, zero
comments, `updated_at` unchanged since 2026-07-21T05:34 UTC. No new GitHub
issues exist beyond these three standing trackers (`gh`-equivalent
`list_issues` returns exactly the three `[Action required]` issues, nothing
else open), and `docs/roadmap/incoming/` is empty (no pending architect items
to absorb). The "Cross-cutting hardening & quality" filler section in
ROADMAP.md has every item either checked off or already groomed into a 🟢
*Now / next* item (crossed out with a `Groomed ↗` note) — nothing unclaimed
remains there either.

## This cycle's fresh angle

Earlier cycles today swept Helm **chart** index hosts (`*.github.io` Pages,
`public.ecr.aws`, `charts.external-secrets.io`, etc. — mostly proxy-blocked;
`istio-release.storage.googleapis.com` reachable and re-confirmed current).
This cycle instead swept every **raw container image tag** pinned directly in
`gitops/` (not fronted by a Helm chart's own `appVersion`) against Docker Hub,
which is reachable from this sandbox (`hub.docker.com` → HTTP 200,
`registry.hub.docker.com` and every `*.github.io` / `charts.jetstack.io` /
`helm.cilium.io` / `charts.longhorn.io` / `helm.goharbor.io` host tested →
still `403` via the proxy, consistent with every prior cycle's finding).

Checked directly against `https://hub.docker.com/v2/repositories/<repo>/tags`:

| Image | Pinned in repo | Newest Docker Hub tag found | Verdict |
|---|---|---|---|
| `dxflrs/garage` | `v2.3.0` | (no newer semver tag surfaced; recent pushes are commit-hash tags only) | current |
| `grafana/loki` | `3.7.4` | `3.7.4` (pushed 2026-07-22, same day as the `3.7` floating tag) | current |
| `grafana/mimir` | `3.1.4` | `3.1.4` (newest by `last_updated`, ahead of `3.1.3`/`3.0.8`) | current |
| `grafana/tempo` | `2.10.7` | confirmed via direct tag lookup; `2.10.8`/`2.10.9`/`2.11.0`/`2.11.1` all `404` | current |
| `hashicorp/vault` | `2.0.3` | `2.0.3` (newest `2.0.x`/`2.x` semver tag) | current |
| `motoserver/moto` | `5.2.2` | `5.2.2` (newest semver tag) | current |
| `danielqsj/kafka-exporter` | `v1.9.0` | `v1.9.0` (newest semver tag) | current |
| `curlimages/curl` | `8.21.0` | `8.21.0` (newest semver tag) | current |

Every one of these eight images is already pinned to Docker Hub's newest
published tag as of this cycle. No actionable version gap found. (The other
pinned images — `apache/kafka`, `rabbitmq`, `valkey/valkey`,
`oliver006/redis_exporter`, `docker.io/grafana/grafana`, `postgres`,
`nginx:alpine`, `jaegertracing/example-hotrod:latest`,
`cloudlena/s3manager:latest`, `ghcr.io/aiven/inkless:latest` — were already
re-verified or explicitly held in prior cycles this week; `postgres`/
`nginx:alpine`/the two `:latest`-pinned images intentionally float per their
own ADR/ROADMAP entries and are out of scope for a pin-bump sweep.)

Also re-checked, network-independent, as this cycle's janitor-lane pass:
every `scripts/*.sh` and `scripts/lib/*.sh` file has at least one reference in
`tests/*.bats` (no coverage gap); no undocumented `TODO`/`FIXME`/`XXX` markers
outside the two already-intentional, already-documented ones
(`gitops/kyverno/policies/disallow-latest-tag.yaml`'s deliberate
`global.image.tag: latest` exception, `infra/modules/argocd/values.yaml`'s
tracked upstream-commit TODO); every ADR `## Re-evaluation log` flip condition
with a 2026-07/08 date is already actioned and logged. `make ci` is fully
green locally (readme-check, lab-ui-check, roadmap-check, all drift detectors
pass with no warnings).

## What would unblock further work

Unchanged from prior cycles today: (a) maintainer confirmation on
#631/#632/#633; (b) a new upstream CVE/release firing a tracked ADR flip
condition; (c) a new GitHub issue of any size; (d) proxy access to the
Helm chart index hosts this sandbox still cannot reach, which would let the
handful of remaining unswept **chart** pins (`ack-s3`, `kro`, `keda`,
`external-secrets`, `trivy-operator`, `vault` chart, `cilium`,
`argo-rollouts`, `velero`, `kyverno`, `cert-manager`, `tidb-operator`,
`longhorn`, `harbor` chart, `grafana`, `kube-state-metrics`, `node-exporter`,
`pyroscope`, `alloy`) be verified directly instead of relying on their last
successful sweep.

This note is this cycle's honest record — not a stopping point. The run
continues to the next cycle per `executor.prompt.md` STEP 8.
