# [Action needed] Now/next still gated; fourth-angle currency + coverage sweep clean after two real fixes landed this run

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items this
run's earlier cycles already found gated:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (last comment
   2026-08-06 07:38 UTC, no new signal since — same live Harbor/host-capacity
   blocker described there).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (same timestamp,
   same blocker).

Re-confirmed via a fresh open-issues list this cycle: exactly 3 open issues
exist (#631, #633, #1034 — the disk-pressure tracking issue), all standing
`[Action required]` gates, no new comment on any since the last check earlier
this run. Re-confirmed via a fresh open-PR list: 0 open PRs.

## This run's real output so far (context for this cycle's "why nothing new")

This run has already landed two real, merged fixes via the PLANNER fallback
this session: `auto/loki-3-7-6` (#1042, Loki `3.7.5`→`3.7.6`, a real
query-correctness fix) and `auto/grafana-image-13-0-5` (#1044, Grafana
`13.0.3`→`13.0.5`, a real `Security:`-tagged CVE fix, plus a Tempo ADR
log-drift correction). Both closed real, verified gaps found by this run's
own currency sweeps.

## This cycle's fresh angle

Per STEP 8's "widen the lens" guidance — this run's prior two cycles already
covered Loki specifically, then Mimir/Grafana/RabbitMQ/Valkey — this cycle
checked a fourth, disjoint set of GitHub-hosted `image:`/chart pins not yet
touched this run, all verified directly (not assumed, ADR-0004):

- **Jaeger hotrod** (`jaegertracing/example-hotrod:2.20.0`): `git ls-remote
  --tags jaegertracing/jaeger` shows `v2.20.0` is the newest tag. Current.
- **kafka-exporter** (`danielqsj/kafka-exporter:v1.9.0`): `git ls-remote
  --tags danielqsj/kafka_exporter` shows `v1.9.0` is the newest tag. Current.
- **redis_exporter** (`oliver006/redis_exporter:v1.88.0`): `git ls-remote
  --tags oliver006/redis_exporter` shows `v1.88.0` (2026-07-23) is the newest
  — a stray `v1.9.0` tag also exists but is a 2020-era leftover from before
  the project's versioning scheme changed (`git log -1 --format=%ai v1.9.0`
  → 2020-07-07), not a newer release; verified by date, not string-sorted by
  mistake. Current.
- **moto** (`motoserver/moto:5.2.2`): `git ls-remote --tags getmoto/moto`
  shows `5.2.2` is the newest tag. Current.
- **curl** (`curlimages/curl:8.21.0`): `git ls-remote --tags curl/curl`
  shows `curl-8_21_0` is the newest release tag. Current.
- **Envoy Gateway** (`gitops/platform/envoy-gateway.yaml`'s OCI chart pin
  `v1.8.3`, `repoURL: docker.io/envoyproxy`): Docker Hub's public tags API
  for `envoyproxy/gateway-helm` (reachable, unlike most `*.github.io` chart
  hosts this session's network policy blocks) shows `v1.8.3` is the newest
  tag across two full pages of results. Current.

Also re-checked non-image angles this cycle:
- **CHARTER Objectives.** O1/O2/O5 already marked met in ROADMAP's own status
  note; O3 (`make dr-restore`), O6 (`make capstone-demo`), O7 (`make
  dora-metrics`) all have their measurement mechanism wired (Makefile targets
  + matching `tests/dr-restore.bats` / `tests/capstone-demo.bats` /
  `tests/dora-metrics.bats` all exist) — no CHARTER-vs-repo gap found. O4 is
  the known, already-tracked gate (issues #631/#633 above).
- **Un-RFC'd 🟡 items.** Grepped ROADMAP.md for `- [ ] 🟡` — zero matches;
  every 🟡 reference in the file is prose (the readiness-tag legend, executor
  notes on Yellow-by-default touches), not an actual pending item.
- **`adr-audit`-labeled issues.** Zero open — nothing stranded for the
  architect fallback role to close out.
- **Script test-coverage completeness.** Cross-checked every `scripts/*.sh`
  against `tests/*.bats` — every script has at least one referencing test
  file. No gap (matches this run's own earlier `make ci` green runs and a
  same-day prior cycle's independent sweep,
  `docs/backlog/2026-08-06-action-needed-cycle22-fresh-currency-sweep-clean.md`).
- **Garage** (`dxflrs/garage:v2.3.0`): not independently re-verified this
  cycle — the same-day `cycle22` note above already confirmed `v2.3.0` is
  current via `deuxfleurs-org/garage`'s GitHub mirror; no reason to assume
  drift in the hours since.

## Assessment

Every clusterless verification angle reachable this cycle — a disjoint set
of image/chart pins from this run's prior two cycles, CHARTER Objectives,
un-RFC'd 🟡 items, open ADR audits, and script coverage — comes back clean.
The three gated Now/next items remain blocked on the same live-cluster facts
only a hands-on session can supply. This cycle's honest deliverable is this
record, not a fabricated bump — the run already shipped two real fixes this
session and continues to the next cycle.

## What would unblock further work

(a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub
issue (intake); (c) a new upstream release/CVE firing a tracked flip
condition; (d) a future cycle re-attempting the four `*.github.io`-hosted
chart repos this session's network policy blocked
(`kyverno.github.io`/`aquasecurity.github.io`/`vmware-tanzu.github.io`/
`argo-helm.github.io`) from an environment with broader reach, or via each
chart's underlying app-repo GitHub releases instead of the chart repo
directly; (e) the still-open ArgoCD Terraform-chart `10.2.2`→`10.2.3`
diligence flagged by the 2026-08-05 planner note (unresolved).

Per `executor.prompt.md` STEP 8 this is not a stopping point — the run
continues to the next cycle.
