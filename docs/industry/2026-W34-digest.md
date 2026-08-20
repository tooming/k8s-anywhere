# Industry digest — week 2026-W34

_Period: 2026-08-17 – 2026-08-23. Originally fetched and written 2026-08-17
(architect-fallback cycle, fourth cycle of that run). **Refreshed 2026-08-18**
(architect-fallback cycle, `executor.prompt.md` STEP 6b, sixth cycle of a new run —
per STEP 1c, refreshed in place rather than creating a second file for the same ISO
week) after this run's own major finding: CHARTER **Objective O4** ("every image is
signed and verified") landed both of its measurement criteria — see "At-a-glance"._
**Refreshed again 2026-08-19** (architect-fallback cycle, `executor.prompt.md`
STEP 6b, a later run — two of the 2026-08-18 pass's own open items resolved
since then: Cilium's `1.18.13` patch shipped and was pinned same-day, and
RabbitMQ's `4.3.5-management` image (reported "not groundable yet" in the
2026-08-18 pass) now resolves and was pinned. See "At-a-glance" for both.
**Refreshed again 2026-08-20** (architect-fallback cycle, `executor.prompt.md`
STEP 6b, third cycle of a new run — Mimir's image tag bumped `3.1.4`→`3.1.5`
(a Go-stdlib CVE fix, `upgrade/mimir-3-1-4-to-3-1-5`, PR #1279) and ADR-0030
(k3s) got its first dedicated GHSA-advisory sweep since its 2026-08-05 bump
(the prior "reconfirmed" mention below only checked the version pointer, not
published advisories) — kept, all three published k3s GHSAs already
exceeded by the current pin (ADR audit #1281). See "At-a-glance" for both.

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
- **RESOLVED since 2026-08-18: RabbitMQ `4.3.5` is now groundable and
  pinned.** The 2026-08-18 pass reported `4.3.5`/`4.3.5-management` both
  404ing on Docker Hub; a later cycle re-checked and found the image now
  resolves, and the bump landed same-run — pinned to
  `rabbitmq:4.3.5-management` (`gitops/data/rabbitmq/statefulset.yaml`,
  confirmed live in this checkout). Per `docs/dependency-register.md`'s
  RabbitMQ row, the bump also turned out to fix 10 real GHSAs disclosed
  2026-08-18 (1 High / 4 Moderate / 5 Low) — corrected same run from an
  initial "no CVE" read. Flip condition closed; no further action.
- **RESOLVED since 2026-08-18: Cilium bumped `1.18.12`→`1.18.13`.** A later
  cycle found `v1.18.13` (released 2026-08-18, one day after this digest's
  prior pass) — patched three High-severity GHSAs
  (GHSA-33qq-jq9c-6gcc/GHSA-xqhm-7xhv-6ppj/GHSA-vh48-r624-p8v7) that this
  lab's prior pin already sat past the fix floor for regardless, so this is
  a routine patch-currency bump, not a CVE-driven one — `git ls-remote
  --tags` confirmed `v1.18.13` is the newest `1.18.x` tag, and a
  `values.yaml` byte-diff confirmed image-tag-only changes, no schema
  churn. Now live at `gitops/platform/cilium.yaml`'s `targetRevision:
  1.18.13` — confirmed directly in this checkout, matching
  `docs/dependency-register.md`'s Cilium row.
- **New this cycle: Vault Helm chart `0.34.0`→`0.34.1`** — a real upstream
  tag (`hashicorp/vault-helm`, 2026-08-13), found by this cycle's own
  UPGRADE-DRAFTER-fallback pass (Vault isn't on this routine's STEP 1
  fetch list — no dedicated ADR — so it wasn't covered by an earlier
  architect cycle). `values.yaml` diff shows only default-image-tag bumps
  this lab's own explicit `server.image.tag` pin already overrides, plus
  an irrelevant license-secret-volume fix — zero rendered-manifest impact.
  Opened as `auto/vault-chart-0-34-0-to-0-34-1` (PR #1269), self-review/
  merge pending as of this digest refresh.
- **Grafana `13.0.5`→`13.0.6`** (real tag, 2026-08-07) — already investigated and
  correctly left unbumped in the 2026-W33 digest (a dashboard-snapshot
  `deletekey` backport this lab doesn't use, not a security fix); re-confirmed
  the same conclusion this pass, no new information changes it.
- **New this cycle (2026-08-20): Mimir image tag `3.1.4`→`3.1.5`** — a
  same-line Go-stdlib CVE bump (8 CVEs fixed, zero config/flag surface
  change; found by this cycle's own UPGRADE-DRAFTER-fallback pass — Mimir
  isn't on this routine's STEP 1 fetch list, no dedicated CVE-tracking
  history beyond ADR-0034). Deliberately did NOT jump to the newer `3.2.0`
  minor — its changelog carries real behavioral/config `[CHANGE]`s and an
  explicit coordinated-upgrade requirement needing live-cluster
  verification. Opened as `upgrade/mimir-3-1-4-to-3-1-5` (PR #1279),
  self-reviewed and merged same cycle.
- **New this cycle (2026-08-20): ADR-0030 (k3s) re-audited, kept** — its
  last audit (2026-08-05) predates this run's 2026-08-19 GHSA-sweep round,
  which covered most other ADR'd components but not k3s. This cycle gave
  it its first dedicated advisory-page sweep: all three published k3s
  GHSAs are already exceeded by the current `v1.36.3+k3s1` pin (the
  most recent, GHSA-jxr7-mqhw-9p98, fixed at `v1.35.3+k3s1` — a full minor
  line behind this lab's pin). ADR audit #1281, opened and resolved Keep
  same cycle; see ADR-0030's own Re-evaluation log for the full finding.
- No other open `adr-audit` issues to close (STEP 2), no un-RFC'd 🟡
  ROADMAP item to decide (STEP 3/4), and no other new ADR-audit-worthy
  finding surfaced (STEP 2b) beyond the k3s audit above — every other
  existing ADR'd choice remains sound against this week's releases.

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
- **RabbitMQ** (`rabbitmq/rabbitmq-server`) — `4.3.5` GitHub release,
  reported not-yet-groundable in the 2026-08-18 pass, now groundable and
  pinned (`rabbitmq:4.3.5-management`, confirmed live in this checkout).
  See "At-a-glance" above.
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

- **k3s** (`v1.36.3+k3s1` — the 2026-08-19 pass verified the version pointer;
  the 2026-08-20 pass added a first dedicated GHSA-advisory sweep, kept, see
  "At-a-glance" above and ADR audit #1281), **Vault Helm chart**
  (bumped `0.34.0`→`0.34.1` this cycle — see "At-a-glance" above), **Cilium**
  (bumped `1.18.12`→`1.18.13` a later cycle since this row was last written
  — see "At-a-glance" above; `1.21.0-pre.0` is still pre-release only, no
  action), **Kyverno** (`3.8.2`; only `-rc` releases exist beyond it on the
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

**2026-08-19 refresh — still no new RFC/audit work.** Two claims in the
2026-08-18 pass had gone stale within a day (RabbitMQ's groundability,
Cilium's pinned version) — both corrected above, plus the new Vault chart
finding. No open `adr-audit` issue, no un-RFC'd 🟡 item, no new
audit-worthy finding this pass either — every existing ADR'd choice
remains sound.

---

## Cadence

This is the fourth entry produced under `architect.prompt.md` STEP 1c's now-mandatory
digest-write contract, after [2026-W32](2026-W32-digest.md) (the cadence-resumption
entry) and [2026-W33](2026-W33-digest.md) — refreshed in place four times within the
same ISO week (2026-08-17, 2026-08-18, 2026-08-19, then 2026-08-20) rather than
forking a second file, per STEP 1c's own instruction. The mechanism continues to
hold: this file was touched again because a later run reached the ARCHITECT
fallback role, and that role's own contract requires writing/refreshing this file
unconditionally, not because anyone remembered to do it by hand. It also continues
to catch real drift — two of the 2026-08-18 pass's own claims (RabbitMQ
groundability, Cilium's pinned version) were already stale by the next day, and the
2026-08-20 pass found k3s's own audit trail (last touched 2026-08-05) had gone
stale relative to the rest of the ADR set, exactly the kind of staleness a
refresh-on-every-cycle contract exists to catch rather than let compound.
