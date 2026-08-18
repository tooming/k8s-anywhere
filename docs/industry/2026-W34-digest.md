# Industry digest — week 2026-W34

_Period: 2026-08-17 – 2026-08-23. Originally fetched and written 2026-08-17
(architect-fallback cycle, fourth cycle of that run). **Refreshed 2026-08-18**
(architect-fallback cycle, `executor.prompt.md` STEP 6b, sixth cycle of a new run —
per STEP 1c, refreshed in place rather than creating a second file for the same ISO
week) after this run's own major finding: CHARTER **Objective O4** ("every image is
signed and verified") landed both of its measurement criteria — see "At-a-glance"._

---

## At-a-glance

- **CHARTER Objective O4 substantially complete, 2026-08-18 (this run, not a
  digest-fetch finding — recorded here for continuity).** Issue #631's
  maintainer-confirmation gate (a real signed image observed landing in Harbor,
  independently verified via Harbor's own artifact API) finally landed after
  weeks of live-cluster investigation across many prior sessions. This run built
  and merged both of O4's remaining gated items the same cycle the confirmation
  arrived: the `verifyImages` ClusterPolicy `Audit`→`Enforce` flip
  (`auto/cosign-enforce-flip`, PR #1223, closed #631) and the CI step proving an
  unsigned image is rejected (`auto/o4-ci-rejection-gate`, PR #1224). Both still
  carry an ADR-0004 caveat: no live Forgejo Actions run has executed either job
  end-to-end yet (the rejection-gate job also needs a `KUBECONFIG` secret the
  maintainer hasn't set up). ROADMAP.md's Now/next status note updated to match
  (`plan/o4-status-update`, PR #1225).
- **Two real currency gaps found and shipped the prior run** (not ADR'd
  components, so out of this routine's STEP 1 fetch list, but worth recording here
  for continuity): ACK s3-controller chart `1.9.0`→`1.10.0` (adds a Bucket ABAC
  field, #1203) and kube-state-metrics chart `8.3.0`→`8.3.1` (packaging-only
  autosharding-Service fix this lab doesn't exercise, #1204). This run added a
  third: the Terraform-bootstrapped `argo-cd` chart `10.3.3`→`10.4.0`
  (`upgrade/argocd-10.3.3-to-10.4.0`, PR #1221 — a distinct enumeration pass,
  `infra/`-pinned rather than `gitops/`-pinned, that prior currency sweeps this
  run's history hadn't covered).
- **A major live event the prior week, not this routine's own action**: a
  concurrent interactive session opened, and the maintainer merged,
  [PR #1205](https://github.com/tooming/k8s-anywhere/pull/1205) doing the actual
  GitLab→Forgejo `repoURL` cutover live. GitLab is now stopped, Forgejo is the
  live git source — confirmed durably still true this run (the O4 confirmation
  evidence itself traced to a live Forgejo Actions run). ROADMAP Now/next's two
  remaining GitLab→Forgejo items (script/Makefile rename, full decommission)
  were investigated this run's history and correctly found **not** a simple
  "now unblocked" mechanical follow-up as an earlier digest pass assumed — the
  rename needs a genuinely different auth mechanism (SSH deploy keys, not
  HTTPS+PAT) that needs live verification this remote session can't perform;
  both items remain deliberately deferred with findings recorded inline in
  ROADMAP.md, not silently stalled.
- **Envoy Gateway `v1.8.3`→`v1.9.0`** (stable since 2026-08-15): re-verified this
  cycle, still correctly kept — see "Lab stack" below. **Now formally recorded**
  in [ADR-0008](../decisions/adr-0008-envoy-gateway-not-traefik.md)'s own
  Re-evaluation log (it previously only lived in a `docs/done/` record, the
  prior digest pass, and this file — this cycle closed that self-tracking-log
  gap, matching the convention every other kept audit on that page follows).
- **New this cycle: RabbitMQ `4.3.5`** — a real GitHub release
  (`rabbitmq/rabbitmq-server`, tagged 2026-08-17) exists, but **not groundable
  yet**: `docker.io/rabbitmq/rabbitmq:4.3.5` and `:4.3.5-management` both 404 on
  Docker Hub as of this check — no pinnable image published. Per this repo's own
  convention (a version with no deployable artifact isn't groundable, ADR-0004),
  not bumped. Flip condition: revisit once the `4.3.5-management` tag actually
  resolves.
- **Grafana `13.0.5`→`13.0.6`** (real tag, 2026-08-07) — already investigated and
  correctly left unbumped in the 2026-W33 digest (a dashboard-snapshot
  `deletekey` backport this lab doesn't use, not a security fix); re-confirmed
  the same conclusion this pass, no new information changes it.
- No open `adr-audit` issues to close (STEP 2), no un-RFC'd 🟡 ROADMAP item to
  decide (STEP 3/4), and no new ADR-audit-worthy finding surfaced (STEP 2b) —
  every existing ADR'd choice remains sound against this week's releases.

---

## Lab stack

Findings below are grouped by whether this cycle re-fetched the source directly or
is citing an already-verified result from this same run's earlier cycles (per
ADR-0004, never re-assert a fact not actually checked this run).

### Re-fetched directly this cycle

- **Envoy Gateway** (`envoyproxy/gateway`) — `v1.9.0` re-confirmed still the
  newest stable tag (no newer release since the 2026-08-17 check). Real
  breaking changes exist upstream, still unaddressed by this lab's tooling.
  **Not bumped** — see "At-a-glance" above; now recorded in ADR-0008's own
  Re-evaluation log with a concrete flip condition.
- **RabbitMQ** (`rabbitmq/rabbitmq-server`) — new `4.3.5` GitHub release found
  this cycle, not yet groundable (no Docker Hub image published). See
  "At-a-glance" above.
- **Grafana** (`grafana/grafana`) — `v13.0.6` confirmed as a real tag (2026-08-07),
  same conclusion as the 2026-W33 digest: single non-security backport, not
  chased.
- **Loki** (`grafana/loki`) — `v3.7.6` reconfirmed as the newest tag on its line
  (probed `v3.7.7`/`v3.8.0`, both 404). No action.
- **node-exporter** (`prometheus-community/helm-charts`,
  `prometheus-node-exporter` chart) — `4.56.1` reconfirmed newest (probed
  `4.56.2`/`4.57.0`, both 404). No action.
- **Garage** (`deuxfleurs/garage`) — `v2.3.0` reconfirmed newest via the
  `deuxfleurs-org/garage` GitHub mirror (the canonical `git.deuxfleurs.fr` host
  remains blocked by this session's egress proxy, same block prior digests
  reported — the mirror gave a real, checkable answer this time). No action.
- **TiDB Operator** (`pingcap/tidb-operator`) — `1.6.6` reconfirmed current
  (probed `v1.6.7`, 404); still within ADR-0031's `1.6.x`-line carve-out, already
  bumped from `1.6.5` earlier this run's day.
- **Longhorn** (`longhorn/longhorn`) — `v1.12.1` is now the newest *overall* tag
  (a real stable release, 2026-08-14), but ADR-0013's Re-evaluation log
  deliberately holds this lab one minor line behind (`1.11.x`) until the `1.12.x`
  line's V2 Data Engine GA proves out or a flip condition (line end-of-support,
  or a CVE against `1.11.3`) fires — neither has. `1.11.3` remains the newest
  patch on the held line (probed `v1.11.4`, only `-dev-*` tags exist, no stable
  release). **Kept**, no new Re-evaluation log entry needed — the existing
  2026-07-28 entry's flip condition is unchanged and still unfired.
- **actions/checkout**, **hashicorp/setup-terraform**, **actions/cache**,
  **actions/github-script** (this repo's pinned GitHub Actions) — all four
  reconfirmed at their newest stable tag. No action. (Not ADR'd components, but
  checked as part of this run's broader currency sweep — recorded here for
  completeness.)

### Reconfirmed from this run's earlier cycles (not re-fetched cold this pass)

- **k3s** (`v1.36.3+k3s1`, independently re-verified this cycle against
  `k3s-io/k3s`'s own `channel.yaml` stable pointer), **Vault Helm chart**
  (`0.34.0`), **Cilium** (`1.18.12` stable; `1.21.0-pre.0` is pre-release only,
  no action), **Kyverno** (`3.8.2`; only `-rc` releases exist beyond it on the
  `3.9.0` line), **Istio** + **Kiali** (`1.30.3` / `2.30.0`; `1.31.0-beta.1` is
  pre-release only), **Argo Rollouts** (`2.41.1`), **Velero** (`velero-12.1.0`),
  **Trivy Operator** (chart `0.35.0`, appVersion `0.33.0` — a distinct repo from
  the `aquasecurity/trivy` scanner binary's own `v0.74.0` release this cycle
  checked; no evidence of trivy-operator-specific drift, flagged as a scope gap
  rather than asserted stale), **cert-manager** (`1.21.1`), **KEDA** (`2.20.2`),
  **Harbor** (`1.19.2` chart, bundling appVersion `v2.15.2` — matches the
  `goharbor/harbor` release re-checked this cycle), **external-secrets**
  (`2.9.0`), **kro** (`0.9.3`), **ArgoCD** (chart already bumped
  `10.3.3`→`10.4.0` this run, PR #1221; `appVersion v3.5.1` matches
  `argoproj/argo-cd`'s own newest release, re-checked this cycle) — every one
  reconfirmed at the newest stable release, no new information beyond what's
  detailed in "At-a-glance"/"Re-fetched directly this cycle" above.

---

## For the architect

- No open `adr-audit` issue existed to close (STEP 2 — no-op this cycle).
- STEP 2b's "meaningfully changes the tradeoff" bar wasn't met by any finding
  above — every ADR'd choice remains sound. Envoy Gateway's `v1.9.0` is a real,
  material upstream event but is a *currency* question for upgrade-drafter/
  executor to verify live, not an *architecture* question (ADR-0008's choice of
  Envoy Gateway itself is unaffected) — and it's now durably recorded in that
  ADR's own Re-evaluation log, closing the gap this section flagged in the
  2026-08-17 pass (it had only lived in a `docs/done/` record and this digest).
- **Resolved since the 2026-08-17 pass**: `docs/dependency-register.md`'s
  GitLab row was corrected to a Forgejo row
  (`auto/dependency-register-gitlab-to-forgejo`, PR #1209) and ROADMAP Now/next
  item 1 was marked `[x]` — both already landed before this digest refresh.
  Items 2/3 (script rename, full decommission) were investigated this run's
  history (not this digest cycle) and found genuinely **not** a simple
  mechanical follow-up — see the ROADMAP items' own inline investigation notes
  for the auth-model finding (SSH deploy keys vs. HTTPS+PAT) that makes a blind
  rename unsafe. No architect action needed; this is executor-lane
  live-verification work, correctly left deferred rather than forced.

No new RFCs opened, no ADR audits opened or closed this cycle — nothing found that
meets STEP 2b's "meaningfully changes the tradeoff" bar. This cycle's real
architect-lane deliverable was closing the ADR-0008 self-tracking-log gap (above),
not a new RFC/audit.

---

## Cadence

This is the third entry produced under `architect.prompt.md` STEP 1c's now-mandatory
digest-write contract, after [2026-W32](2026-W32-digest.md) (the cadence-resumption
entry) and [2026-W33](2026-W33-digest.md) — refreshed in place twice within the same
ISO week (2026-08-17, then 2026-08-18) rather than forking a second file, per STEP
1c's own instruction. The mechanism continues to hold: this file was touched again
because a later run's sixth cycle reached the ARCHITECT fallback role, and that
role's own contract requires writing/refreshing this file unconditionally, not
because anyone remembered to do it by hand.
