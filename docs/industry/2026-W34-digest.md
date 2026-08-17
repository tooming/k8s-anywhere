# Industry digest — week 2026-W34

_Period: 2026-08-17 – 2026-08-23. Fetched and written 2026-08-17 (architect-fallback
cycle, `executor.prompt.md` STEP 6b, fourth cycle this run — after three prior
cycles already shipped `auto/ack-s3-chart-1-10-0` (PR #1203), `auto/ksm-chart-8-3-1`
(PR #1204), and an `[Action needed]` record (PR #1206) documenting an exhaustive
currency sweep across ~30 pinned sources; the six standing Now/next items were
re-checked and found still gated on #631/#633)._

---

## At-a-glance

- **Two real currency gaps found and shipped earlier this run** (not ADR'd
  components, so out of this routine's STEP 1 fetch list, but worth recording here
  for continuity): ACK s3-controller chart `1.9.0`→`1.10.0` (adds a Bucket ABAC
  field, #1203) and kube-state-metrics chart `8.3.0`→`8.3.1` (packaging-only
  autosharding-Service fix this lab doesn't exercise, #1204).
- **A major live event this week, not this routine's own action**: a concurrent
  interactive session opened [PR #1205](https://github.com/tooming/k8s-anywhere/pull/1205)
  doing the actual GitLab→Forgejo `repoURL` cutover live, per explicit maintainer
  direction — GitLab is now stopped, Forgejo is the live git source. Still open
  (unmerged) as of this digest. Once it lands it satisfies ROADMAP Now/next item 1
  of the Forgejo-migration list; items 2/3 (script rename, GitLab decommission)
  remain explicit follow-up per that PR's own body.
- **A full STEP 1 sweep against every ADR'd component this week** found no new
  release meeting the "meaningfully changes the tradeoff" bar (STEP 2b) — see
  "Lab stack" below for the per-component findings, most reconfirmed current from
  this run's own earlier currency-sweep cycles rather than re-fetched cold.
- **One real, non-major upstream release found but deliberately not chased this
  cycle**: Envoy Gateway `v1.8.3`→`v1.9.0` went stable 2026-08-15 (two days before
  this run). Real breaking changes in the fetched changelog, including a Gateway
  API CRD version requirement — this lab's sync-wave-0, always-on-core ingress
  control plane (ADR-0008) — deferred as a finding for a live-cluster or
  `helm`-equipped session rather than blind-bumped. See `docs/backlog/
  2026-08-17-action-needed-currency-sweep-exhausted-cycle3.md` for the full
  reasoning (already filed this run, PR #1206, merged).
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

- **Envoy Gateway** (`envoyproxy/gateway`) — `v1.9.0` now stable (released
  2026-08-15), superseding the `v1.9.0-rc.1` the 2026-08-12 digest refresh saw.
  Real breaking changes exist upstream. **Not bumped** — see "At-a-glance" above.
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

- **k3s** (`v1.36.3+k3s1`), **Vault Helm chart** (`0.34.0`), **RabbitMQ**
  (`4.3.4-management`, kept — CVE-2026-57221 already fixed at this pin), **Cilium**
  (`1.18.12`), **Kyverno** (`3.8.2`, only `-rc` releases exist beyond it on the
  `3.9.0` line), **Istio** + **Kiali** (`1.30.3` / `2.30.0`), **Argo Rollouts**
  (`2.41.1`), **Velero** (`velero-12.1.0`), **Trivy Operator** (chart `0.35.0`,
  appVersion `0.33.0`), **cert-manager** (`1.21.1`), **KEDA** (`2.20.2`), **Harbor**
  (`1.19.2`), **external-secrets** (`2.9.0`), **kro** (`0.9.3`) — every one
  reconfirmed at the newest stable release this run's cycle 3 sweep already
  verified, no new information this pass.

---

## For the architect

- No open `adr-audit` issue existed to close (STEP 2 — no-op this cycle).
- STEP 2b's "meaningfully changes the tradeoff" bar wasn't met by any finding
  above — every ADR'd choice remains sound. Envoy Gateway's `v1.9.0` is a real,
  material upstream event but is a *currency* question for upgrade-drafter/
  executor to verify live, not an *architecture* question (ADR-0008's choice of
  Envoy Gateway itself is unaffected).
- **Worth a future architect's attention, not opened as a formal audit this
  cycle** (no upstream release triggered it — this is a repo-internal
  observation, outside STEP 2b's own trigger criteria): PR #1205's live GitLab→
  Forgejo cutover this week means `docs/dependency-register.md`'s GitLab row
  (still describing GitLab as "the live, running component") and ADR-0033's
  posture will both go stale once that PR merges — flagging for whichever role
  picks up the ROADMAP migration-list follow-up items (rename scripts, GitLab
  decommission) to also refresh those docs in the same pass, not a separate
  architect action.

No new RFCs opened, no ADR audits opened or closed this cycle — nothing found that
meets STEP 2b's "meaningfully changes the tradeoff" bar.

---

## Cadence

This is the third entry produced under `architect.prompt.md` STEP 1c's now-mandatory
digest-write contract, after [2026-W32](2026-W32-digest.md) (the cadence-resumption
entry) and [2026-W33](2026-W33-digest.md). The mechanism continues to hold: this file
exists because this run's fourth cycle reached the ARCHITECT fallback role, and that
role's own contract requires writing/refreshing this file unconditionally, not
because anyone remembered to do it by hand.
