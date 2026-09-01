# Industry digest — week 2026-W36

_Period: 2026-08-31 – 2026-09-06. Written 2026-09-01 (architect-fallback cycle,
`executor.prompt.md` STEP 6b, this run's fifth cycle — PLANNER found no
ungroomed intake and no un-RFC'd 🟡 item across all five cycles so far, so
the chain reached ARCHITECT after four prior cycles produced real
dependency-currency deliverables instead: `plan/valkey-8.1.10-security-bump`
(PR #1360, PLANNER fallback), then three UPGRADE-DRAFTER-fallback bumps —
Valkey `8.1.9`→`8.1.10` (PR #1361, security), Kargo `1.11.2`→`1.11.3` (PR
#1362, authz-bypass fix), and TiDB database `v8.5.7`→`v8.5.8` (PR #1363,
currency). This is the first digest entry since
[2026-W35](2026-W35-digest.md) — no architect-fallback cycle landed in
2026-W36 before this one)._

---

## At-a-glance

- **No new `adr-audit` issue opened this cycle** (STEP 2b) — every upstream
  release found this week for an ADR'd component is either already reflected
  in the lab's pin (this run's own three currency bumps above), a routine
  patch with no security bulletin naming the held version as affected, or
  unchanged from a prior digest's already-recorded hold. Nothing meets the
  "meaningfully changes the tradeoff" bar STEP 2b sets.
- **No open `adr-audit` issue existed to close** (STEP 2 — no-op; checked
  directly, zero issues carry that label).
- **No un-RFC'd 🟡 ROADMAP item exists** (STEP 3/4 — no-op; verified: zero
  `- [ ] 🟡` lines anywhere in ROADMAP.md this cycle, unchanged all run).
- **Three of this week's real findings already landed as this run's own
  earlier cycles**, not left for the architect to merely note: Valkey
  `8.1.10` (SECURITY, GHSA-jcj7-v34w-v9vv), Kargo `1.11.3` (real
  authz-bypass fix, no GHSA yet), TiDB database `v8.5.8` (routine currency
  within ADR-0032's own held line). See their own `docs/done/` writeups and
  ADR-0018/ADR-0023/ADR-0032 Re-evaluation logs for full detail — not
  re-duplicated here.
- **One real, evidenced-but-not-yet-actioned candidate found this cycle**:
  the Terraform-bootstrapped ArgoCD Helm chart (`infra/modules/argocd/`,
  ADR-0001's seam) is pinned to `10.4.0` (`appVersion: 3.5.1`) while
  `argoproj/argo-helm`'s real chart repo has since published `10.5.0`
  (`appVersion: 3.5.2`) — a minor chart bump, no ADR pin blocks it. This is
  exactly the "separate enumeration surface, historically found stale"
  pattern `docs/done/2026-07-23-argocd-chart-bump-9-5-20-to-9-7-1.md`
  documents (`infra/` isn't under `gitops/`, so it needs its own explicit
  walk). Flagged here for a future UPGRADE-DRAFTER-fallback cycle rather
  than bumped in this same cycle, to keep this cycle's own deliverable
  (the digest write) singular and reviewable.
- **Argo Rollouts' running appVersion (`1.9.1`, chart `2.41.1`) is one minor
  release behind upstream's real newest (`1.10.0`, released this week)** —
  also flagged as a future upgrade-drafter candidate, not actioned here.

---

## Lab stack

Every ADR'd component from `architect.prompt.md` STEP 1's checklist,
checked this cycle:

- **k3s** (`k3s-io/k3s`) — newest stable is `v1.36.4+k3s1` (also
  `v1.35.8+k3s1`, `v1.34.11+k3s1` siblings, all same release day). ADR-0030
  pins an explicit version per backend; unchanged from prior digests, no
  action — a k3s bump is its own scoped ADR-0030 decision, not a routine
  currency item.
- **ArgoCD** (`argoproj/argo-cd`) — app release `v3.5.2` exists (newest
  stable). The Terraform-bootstrapped chart (`infra/modules/argocd/`) is
  still pinned to chart `10.4.0`/`appVersion: 3.5.1`, one release behind;
  chart `10.5.0`/`appVersion: 3.5.2` is real and published
  (`argoproj/argo-helm`). **Flagged as a future upgrade-drafter candidate**
  (see At-a-glance) — not bumped this cycle.
- **Cilium** (`cilium/cilium`) — `v1.18.13` reconfirmed still the newest
  `1.18.x` tag (`v1.19.7`/`v1.20.1` exist but are sequential-minor-only
  targets per this ADR's own established policy, not routine-bumpable
  regardless of what's newest overall). ADR-0014's flip condition (an
  `1.18.x` end-of-support date, or a CVE against `1.18.13` specifically)
  unfired. **Kept.**
- **Vault** (`hashicorp/vault`) — `v2.0.4` reconfirmed newest stable,
  matching `gitops/platform/vault.yaml`'s pin. No action.
- **Envoy Gateway** (`envoyproxy/gateway`) — `v1.9.1` (newest stable) and
  `v1.8.4` (newest on the `1.8.x` line) both exist upstream. ADR-0008's own
  Re-evaluation log already holds this lab's pin at `v1.8.3` pending the
  Gateway API CRD version bump this lab's clusterless verification tooling
  can't yet confirm — flip condition unfired, unchanged from every prior
  digest. **Kept.**
- **Grafana** (`grafana/grafana`) — `v13.2.0` (newest overall) exists;
  ADR-0006 holds the chart at the `13.0.x` app-version line
  (`v13.0.7` is that line's newest). A version-line jump needs its own
  deeper diligence per this ADR's established bar — not actioned. **Kept.**
- **Longhorn** (`longhorn/longhorn`) — `v1.12.1` reconfirmed still the
  newest overall tag; `v1.11.3` remains newest on the ADR-0013-held `1.11.x`
  line (V2 Data Engine GA is the deliberate hold reason, not staleness).
  **Kept.**
- **Valkey** (`valkey-io/valkey`) — bumped `8.1.9`→`8.1.10` this run (PR
  #1361, SECURITY release GHSA-jcj7-v34w-v9vv). See ADR-0018's
  2026-09-01 Re-evaluation log entry for the full citation trail. Current.
- **RabbitMQ** (`rabbitmq/rabbitmq-server`) — `v4.3.5` reconfirmed newest,
  matching the live pin. No action.
- **TiDB** (`pingcap/tidb`) — bumped `v8.5.7`→`v8.5.8` this run (PR #1363,
  routine currency within ADR-0032's held `v8.5.x` line). Note on
  verification method: the GitHub HTML release page rendered an implausible
  publish year for this release in this sandbox — the real Atom feed's
  ISO-8601 timestamp was used instead (see ADR-0032's log and
  `docs/done/2026-09-01-tidb-8-5-8-currency-bump.md` for the full method).
  **TiDB Operator** (`pingcap/tidb-operator`) — `v1.6.6` reconfirmed newest
  on the ADR-0031-held `1.6.x` line (the `2.x` line is alpha-only,
  `v2.2.0-alpha.7`). No action.
- **Istio** (`istio/istio`) — `1.31.0` (newest overall, released this week)
  and `1.30.4` (newest on the `1.30.x` line this lab's `istio-base`/
  `istiod`/`cni`/`ztunnel` all pin) both exist. ADR-0012's flip condition is
  specific: revisit only when a new Istio security bulletin names a version
  at or above `1.30.3` as affected — no such bulletin found this cycle for
  `1.30.4`. **Kept** (a routine `1.30.3`→`1.30.4` currency bump remains a
  legitimate future upgrade-drafter candidate, distinct from this ADR's own
  gate, which only concerns a *security-driven* re-evaluation).
- **Garage** (`deuxfleurs-org/garage`) — `v2.3.0` reconfirmed newest tag,
  matching the live pin (`dxflrs/garage:v2.3.0`) exactly. No action.
- **Harbor** (`goharbor/harbor`) — `v2.15.2` reconfirmed newest stable tag
  (only `-rc` pre-releases exist beyond it). No action.
- **Kyverno** (`kyverno/kyverno`) — `v1.19.0` (citing CVE-2026-32280 and
  GHSA-79gf-7frw-68m9) reconfirmed still not a gap: the 2026-08-25 digest's
  own investigation already found this fix landed in `v1.18.0`, two
  releases behind this lab's running `v1.18.2` (chart `3.8.2`). Re-checked
  this cycle: no new advisory exists beyond that one. **Kept.**
- **Argo Rollouts** (`argoproj/argo-rollouts`) — `v1.10.0` (released this
  week) is a real, newer **minor** release above this lab's running
  `v1.9.1` (chart `2.41.1`). Not a major bump (`1.x` line unchanged).
  **Flagged as a future upgrade-drafter candidate** (see At-a-glance) — not
  bumped this cycle, so ADR-0020's own tracking note is intentionally left
  unchanged for now.
- **Velero** (`vmware-tanzu/velero`) — `v1.18.3-rc.1` exists but is a
  pre-release (skipped per policy); `v1.18.2` (the next real stable release
  above this lab's pin) remains **not yet groundable** — re-checked
  directly against `vmware-tanzu/helm-charts`' `velero` chart's real
  `Chart.yaml`: still `version: 12.1.0` / `appVersion: 1.18.1`, unchanged
  since the 2026-08-25 digest first found this gap. **Not actionable.**
- **cert-manager** (`cert-manager/cert-manager`) — `v1.21.1` reconfirmed
  newest stable, matching the live pin. No action.
- **KEDA**, **Trivy** — not re-fetched cold this cycle (both checked within
  the last two weeks per `docs/dependency-register.md`'s own currency
  window; Trivy the scanner binary itself remains a distinct-repo scope gap
  already flagged in the 2026-08-19/2026-W34 digests, unchanged).
- **Kargo** (`akuity/kargo`) — bumped `1.11.2`→`1.11.3` this run (PR #1362,
  real authz-bypass fix, not yet a formally filed GHSA/CVE). See ADR-0023's
  2026-09-01 Re-evaluation log entry. Current.

---

## For the architect

**2026-09-01 (this entry):** no RFCs opened, no ADR audits opened or
closed — every existing ADR'd choice's held line remains sound against this
week's real upstream releases, and this run's own three currency bumps
(Valkey, Kargo, TiDB) already actioned the components that genuinely moved.
Two real, non-security currency gaps were found and flagged for a future
upgrade-drafter cycle rather than actioned here (ArgoCD's Terraform chart,
Argo Rollouts' chart) — see At-a-glance.

---

## Cadence

This is the seventh entry produced under `architect.prompt.md` STEP 1c's
mandatory digest-write contract, after [2026-W35](2026-W35-digest.md) (two
entries within that ISO week — 2026-08-24 original, 2026-08-25 refresh).
The gap between 2026-W35 and this entry (no architect-fallback cycle landed
in 2026-W36 until now) is itself unremarkable — this routine has no cron of
its own; it fires only when an executor run's PLANNER pass finds nothing to
refill the "Now / next" lane and the chain reaches ARCHITECT. This run's own
first four cycles all found real PLANNER/UPGRADE-DRAFTER-fallback work
before the chain ever reached here, which is exactly the chain working as
designed (STEP 6b: "stop at the first role whose contract yields a real
deliverable") — the digest write itself is unconditional per STEP 1c/STEP 9
regardless of how many cycles it takes to get here.
