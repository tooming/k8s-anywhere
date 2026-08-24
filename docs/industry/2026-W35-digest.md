# Industry digest — week 2026-W35

_Period: 2026-08-24 – 2026-08-30. Fetched and written 2026-08-24
(architect-fallback cycle, `executor.prompt.md` STEP 6b, second cycle of this
run — the first cycle's PLANNER-fallback pass found a `dependency-register.md`
drift bug and mechanical guard, `chore/dependency-register-drift-fix-and-guard`,
PR #1297, merged; this cycle's own PLANNER pass found no ungroomed issues, no
`docs/roadmap/incoming/` files, and zero un-RFC'd 🟡 items, so the chain
continued to ARCHITECT)._

---

## At-a-glance

- **No new RFC/audit work this week — but the sweep caught two would-be false
  alarms before they could cause wasted effort**, which is itself the real
  value of this cycle (see "Lab stack" below for the full verification trail):
  - **Kyverno `v1.19.0`** cites "limit intermediate certs to mitigate
    CVE-2026-32280" in its release notes. Cross-checked properly rather than
    taken at face value: that fix actually landed in `v1.18.0` already (per
    Kyverno's own PR #15858, confirmed via a second independent source), and
    this lab's current appVersion (`v1.18.2`, chart `3.8.2`) is two releases
    past it. **Not a gap.** Also checked `v1.19.0`'s other cited fix,
    `CVE-2026-39836` (a Go stdlib `net` package panic) — that CVE is
    **Windows-only** (`Dial`/`LookupPort` panicking on a NUL-byte input on
    Windows); this lab runs Kyverno exclusively on Linux nodes, so it's not
    exposed regardless of version. No chart tag bundling `v1.19.0` exists yet
    on `kyverno-charts` either (checked directly, 404), so there's nothing
    groundable to pin even if either finding had been real.
  - **Velero `v1.18.2`** is a real, newer app release (three routine bugfixes,
    confirmed directly — no security content), but `vmware-tanzu/helm-charts`'
    `velero` chart is still at `12.1.0`/`appVersion: 1.18.1` on its `main`
    branch (checked directly against the live `Chart.yaml`) — not yet
    groundable, same "real release, no chart to pin it with yet" shape as the
    2026-08-18 digest's RabbitMQ finding. **Not actionable this cycle**, flagged
    for a future currency sweep once a chart catches up.
- **No open `adr-audit` issue existed to close** (STEP 2 — no-op).
- **No un-RFC'd 🟡 ROADMAP item exists** (STEP 3/4 — no-op; verified: zero
  `- [ ] 🟡` lines anywhere in ROADMAP.md this cycle).
- **STEP 2b's "meaningfully changes the tradeoff" bar wasn't met by anything**
  found this cycle — every ADR'd technology choice remains sound against this
  week's real upstream releases (see "Lab stack" for the full list checked).

---

## Lab stack

Every entry below was re-fetched directly this cycle (not carried over from a
prior digest) — see the individual finding write-ups above for the two that
needed a second, deeper look.

- **k3s** (`k3s-io/k3s`) — `v1.36.3+k3s1` reconfirmed newest stable (only
  `v1.36.4-rc1+k3s1`/`v1.35.8-rc1+k3s1`/`v1.34.11-rc1+k3s1` release candidates
  exist beyond it, dated 2026-08-21 — pre-release, correctly excluded per
  ADR-0030's "stable release" bar). No action.
- **ArgoCD** (`argoproj/argo-cd`) — `v3.5.1` reconfirmed newest stable,
  matching the Terraform-bootstrapped chart's `appVersion` (chart `10.4.0`).
  No action.
- **Vault** (`hashicorp/vault`) — `v2.0.4` reconfirmed newest stable, matching
  `gitops/platform/vault.yaml`'s explicit `server.image.tag` pin. No action.
- **Envoy Gateway** (`envoyproxy/gateway`) — `v1.9.0` (2026-08-15) reconfirmed
  still the newest stable tag, no newer release since the 2026-08-18/20
  checks. Real breaking changes (Gateway API CRD version bump) still
  unaddressed by this lab's clusterless verification tooling — **still
  correctly kept at `v1.8.3`**, per ADR-0008's own Re-evaluation log and flip
  condition (unchanged, unfired).
- **Longhorn** (`longhorn/longhorn`) — `v1.12.1` reconfirmed still the newest
  *overall* tag; `v1.11.3` remains the newest patch on the ADR-0013-held
  `1.11.x` line. **Kept**, flip condition (line end-of-support or a CVE
  against `1.11.3`) still unfired.
- **Grafana** (`grafana/grafana`) — `v13.0.7` reconfirmed still the newest tag
  on the ADR-0006-held `13.0.x` line. A new **`v13.2.0`** minor release
  (2026-08-18) now exists upstream, alongside the already-known `v13.1.4`
  sibling line — both are version-line jumps this ADR's own established bar
  explicitly excludes from a routine patch bump ("needs its own deeper
  diligence"). Not actioned; no new information changes the held position.
- **Cilium** (`cilium/cilium`) — `v1.18.13` reconfirmed still the newest
  `1.18.x` tag; `SECURITY.md`'s support table (fetched directly) still lists
  `1.18.x` as supported (`:white_check_mark:`), so ADR-0014's flip condition
  ("1.18.x itself reaches end-of-support, or a CVE lands against `1.18.13`
  specifically") remains unfired even though `v1.19.7`/`v1.20.1` now exist —
  Cilium's own sequential-minor-only upgrade path (already established in
  this ADR's 2026-07-30 entry) means neither is a routine-bumpable target
  regardless. **Kept.**
- **RabbitMQ** (`rabbitmq/rabbitmq-server`) — `v4.3.5` reconfirmed newest,
  matching the live pin (`rabbitmq:4.3.5-management`). No action.
- **TiDB Operator** (`pingcap/tidb-operator`) — `v1.6.6` reconfirmed newest on
  the ADR-0031-held `1.6.x` line. No action.
- **Istio** (`istio/istio`) — `1.30.3` reconfirmed newest on its line
  (`1.31.0-rc.0` and beta/alpha builds exist beyond it, all pre-release). No
  action.
- **Garage** (`deuxfleurs-org/garage`) — `v2.3.0` reconfirmed newest via the
  GitHub mirror (same egress-proxy block on the canonical `git.deuxfleurs.fr`
  host prior digests reported). No action.
- **Harbor** (`goharbor/harbor`) — `v2.15.2` reconfirmed newest stable,
  matching the chart's bundled appVersion. No action.
- **Kyverno** (`kyverno/kyverno`) — see "At-a-glance" above for the full
  verification trail. **Kept at `v1.18.2`** (chart `3.8.2`) — both cited
  CVEs in `v1.19.0`'s release notes turned out inapplicable on closer check
  (already-fixed / platform-inapplicable), and no chart exists yet to pin
  `v1.19.0` even if either had been real.
- **Argo Rollouts** (`argoproj/argo-rollouts`) — `v1.9.1` (fixing
  CVE-2026-35469, a real security release) is exactly this lab's *current*
  pinned appVersion (chart `2.41.1` → `appVersion: 1.9.1`, confirmed against
  ADR-0020's own self-tracking "Chart + version" note) — **already fixed**,
  not a gap. Worth recording precisely because the register's 2026-08-19
  "zero advisories" sweep and this finding could easily have been
  misread as a contradiction; they aren't — the CVE is real, and this lab
  is already past it.
- **Velero** (`vmware-tanzu/velero`) — see "At-a-glance" above. `v1.18.2` real
  but not yet groundable (no chart tag bundles it).
- **cert-manager** (`cert-manager/cert-manager`) — `v1.21.1` reconfirmed
  newest stable. No action.
- **KEDA** — not on this cycle's direct-refetch list (checked 2026-08-19 per
  `docs/dependency-register.md`, well within this digest's currency window);
  not re-fetched cold this cycle.
- **Trivy** (`aquasecurity/trivy`) — not re-fetched cold this cycle (Trivy
  Operator, the actual ADR'd/pinned component, was swept 2026-08-19 with zero
  advisories found; the scanner binary itself is a distinct repo already
  flagged as a scope gap in the 2026-W34 digest, unchanged).

---

## For the architect

No new RFCs opened, no ADR audits opened or closed this cycle. Every existing
ADR'd choice remains sound against this week's real upstream releases — this
cycle's actual value-add was catching two currency false alarms (Kyverno's
misattributed CVE fix date, and confirming Argo Rollouts' "new" CVE fix is
already the running version) before either could turn into wasted
upgrade-drafter/executor cycles chasing a non-gap. `docs/dependency-register.md`
itself needed no updates this cycle (its own drift-detection gate,
`scripts/dependency-register-check.sh`, shipped this run's prior cycle,
PR #1297, and reports clean).

---

## Cadence

This is the fifth entry produced under `architect.prompt.md` STEP 1c's
now-mandatory digest-write contract, after
[2026-W32](2026-W32-digest.md) (the cadence-resumption entry),
[2026-W33](2026-W33-digest.md), and [2026-W34](2026-W34-digest.md) (refreshed
four times within its own ISO week). This is the first entry for 2026-W35 —
no prior refresh exists yet this week. The mechanism continues to hold: this
file exists because a run reached the ARCHITECT fallback role and that role's
own contract requires writing this file unconditionally, not because anyone
remembered to do it by hand — and it continues to earn its keep: this week's
entry is itself a record of two currency claims that would have been wrong if
taken at face value, caught only because the digest's own STEP 1 discipline
requires fetching and cross-checking the real source rather than trusting a
release note's own framing.
