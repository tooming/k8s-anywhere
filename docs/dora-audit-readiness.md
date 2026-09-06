# DORA audit Q&A — ready-made structure

**Scope note.** The EU Digital Operational Resilience Act (Regulation (EU) 2022/2554)
applies to regulated financial entities and their critical ICT third-party providers
(Article 2). This lab is neither, so nothing here is a compliance claim or a legal
filing. It exists so the questions a DORA audit/examination would ask have a rehearsed,
honest answer — useful for practice, portfolio write-ups, or as a template to reuse on a
real regulated system later. Every answer below is grounded in this repo's actual state
(per [ADR-0004](decisions/adr-0004-no-fabricated-content.md) — no fabricated posture);
where nothing exists, the answer says so plainly instead of inventing one.

**Companion docs** (this file's evidence draws on both, rather than restating them):
[docs/dora-resilience-mapping.md](dora-resilience-mapping.md) maps DORA's five pillars
onto real repo mechanisms (RFC #586) — read that first for the pillar-level picture;
this file turns it into rehearsed answers to the specific questions an audit would ask.
[docs/dora-metrics.md](dora-metrics.md) (CHARTER Objective O7, `make dora-metrics`,
RFC #580) computes the unrelated "DORA" — DevOps Research and Assessment — delivery
metrics (deployment frequency, lead time, change failure rate, time to restore
service) from real git/CI history; where relevant below it's cited as evidence, not
duplicated.

**Template for a new question (copy this row shape):**

| Field | Content |
|---|---|
| Q | *the audit question* |
| Applicable? | Yes / No — and why |
| Answer | *what's actually true today* |
| Evidence | *file/ADR/command that proves it* |
| Gap / next step | *what's missing, or "none"* |

---

## Pillar 1 — ICT risk management (Ch II)

**Q1. Is there a documented ICT risk management framework?**
- **Applicable?** Loosely — no "management body" exists (it's a personal lab), but the
  equivalent artifact (a written, binding risk/architecture framework) does.
- **Answer:** Yes. [CHARTER.md](../CHARTER.md) states the Core Values and Objectives;
  [docs/decisions/](decisions/) holds a full set of binding ADRs recording every material risk
  decision; [CLAUDE.md](../CLAUDE.md) + [WAYS-OF-WORKING.md](WAYS-OF-WORKING.md) govern
  how changes to it are made.
- **Evidence:** CHARTER.md Core Values section; ADR index.
- **Gap:** none structurally; see Q5 for review-cadence.

**Q2. Are critical functions/assets identified and mapped to supporting ICT systems?**
- **Applicable?** Yes.
- **Answer:** Yes, for the stateful surface. CHARTER Objective O3 names the four
  stateful namespaces (`data`, `capstone`, `vault`, `observability`) as
  critical; the always-on
  vs. on-demand split (12GB budget, ADR-0003) documents which ~53 Applications are
  load-bearing (re-derived 2026-08-25 after KEDA + KRO's engine both converted to
  on-demand for cluster-load reduction, ADR-0029's Re-evaluation log — down from
  "~58" as of the 2026-07-29/issue #846 count; CHARTER's own "Always-on core"
  bullet count is ~32 of those 53; the rest are the always-on next-wave/
  cert-manager/capstone Applications, distinct from the ~5 namespace-only
  PSA-floor shells that merely pre-stage an otherwise on-demand component).
- **Evidence:** [CHARTER.md](../CHARTER.md) O3; [docs/dependency-tree.md](dependency-tree.md).
- **Gap:** closed below — see "Stateless component criticality tiers".

### Stateless component criticality tiers

Every always-on **stateless** component from CHARTER's "Target end-state" section,
tiered using [docs/incident-log.md](incident-log.md)'s existing P0–P3 severity scheme
(reused rather than inventing a second taxonomy) — one row per component, with a
justification grounded in what its *own* outage actually breaks, not a guess. This is
additive to Q2's existing stateful-surface answer (CHARTER O3); on-demand heavy
components (Harbor, Kargo) are out of scope here — their
outage is already covered by the P2 "on-demand/heavy component is broken" row in the
severity scheme itself, and they carry no always-on blast radius by design.

| Component | Tier | Why |
|---|---|---|
| Cilium | **P0** | CNI/network dataplane — the *only* documented P0 in `docs/incident-log.md` to date (2026-07-29: apiserver connectivity loss, cluster-wide). Without it, no pod can reach the apiserver or any other pod. |
| Traefik | **P0** | Sole north-south ingress front door (ADR-0040, supersedes ADR-0008) — every lab UI, the capstone endpoint, and the DR front door all route through it. An outage of the gateway itself (not a NetworkPolicy gap, which is what the two logged 2026-08-04/08-07 incidents actually were, both P1, against the prior Envoy Gateway) means total external unreachability — whole-lab-down by the scheme's own P0 definition, even though no incident has hit this specific failure mode yet. |
| ArgoCD | **P1** | GitOps control plane. Already-running pods keep serving on outage — this is not immediate lab-down — but no new deploys land and drift stops self-healing, matching the P1 definition ("a single always-on component is down or degraded"). |
| Vault | **P1** | Secrets backend. Documented real incident (`gitops/vault/unsealer.yaml`'s header comment): sealed for 4+ days, silently breaking every ExternalSecrets refresh cluster-wide. Already-synced K8s `Secret` objects are untouched — new/rotated secrets stop flowing. Matches P1's "security-relevant gap" language directly. |
| External Secrets Operator | **P1** | Shares Vault's exact blast radius — the two fail together functionally (ESO is the sync mechanism, Vault is the source). |
| Kyverno | **P1** | Admission policy engine. Re-checked directly 2026-09-06 (ADR-0004: the prior version of this row was stale) — `verify-image-signatures.yaml` explicitly sets `failurePolicy: Fail` (flipped from `Ignore` 2026-08-18, per that file's own header comment and ADR-0019's Re-evaluation log), not `Ignore` as this row previously claimed. The other 4 `ClusterPolicy` files (`add-default-runasnonroot`, `add-default-seccomp`, `disallow-latest-tag`, `require-pod-security-restricted`) don't set `failurePolicy` explicitly at all, so their actual webhook behavior on a Kyverno outage depends on Kyverno's own admission-controller default — not independently verified live from this clusterless session, so not asserted either way. Still tiered P1 regardless: an outage during that undetermined-failurePolicy window is, at minimum, a security-relevant gap for those 4 policies (fail-open would silently disable enforcement) even with `verify-image-signatures` itself now fail-closed. |
| Garage | **P1** | S3-compatible object store — backs the entire LGTMP stack's chunk/block storage (Loki/Tempo/Mimir/Pyroscope) *and* Velero's backup target. An outage stops new metrics/logs/traces ingestion and all backups at once — a real, compounding gap even though nothing already-running crashes. |
| Alloy | **P1** | The single collector feeding every Mimir/Loki/Tempo/Pyroscope series in the lab (`prometheus.scrape`/`loki.write`/`otelcol` pipelines all route through it). An outage blinds the *entire* observability stack simultaneously, not just one dashboard — the same "nothing surfaced anywhere visible" failure mode the 2026-08-11 P0 k3s-datastore incident and the Vault-sealed incident both independently illustrate the cost of. |
| GitLab | **P2** | Git source + CI runner (host-level Docker Compose, outside the cluster per ADR-0033/ADR-0035). Matches the real 2026-08-04 incident-log entry for "no GitLab Runner ever registered," logged P2 there — no deploys/CI, but the already-running cluster is unaffected. |
| Grafana | **P2** | Observability UI only — the underlying Mimir/Loki/Tempo/Pyroscope data keeps being written by Alloy even if Grafana itself is down; only the human-facing view is lost. |
| Mimir / Loki / Tempo / Pyroscope / kube-state-metrics / node-exporter | **P2** each | Individual observability stores/exporters — losing any one is a partial, single-signal blind spot (metrics, or logs, or traces, or profiles), not the total blackout Alloy's own outage would cause. Matches P2's "non-blocking functional defect in an always-on component." |
| cert-manager | **P2** | TLS lifecycle. Existing certs keep working until their own expiry; only renewal stops — a slow-burn gap, not an immediate one. |
| KEDA | **P2** | Event-driven autoscaling. Workloads simply stop receiving new scale events and stay at their current replica count — no crash, no traffic loss. |
| RabbitMQ / Valkey | **P2** each | Data layer backing the always-on demo app and the KEDA scaling demo only — no core-lab component depends on either. |
| moto / ACK / KRO | **P2** each | Cloud-control-plane emulation for AWS-resource demos — outage breaks the cloud-demo path only, no core-lab impact. |
| Argo Rollouts | **P2** | Progressive-delivery controller for the capstone canary. Outage freezes new canary rollouts; the currently-active capstone `Rollout` pods keep serving traffic unaffected. |
| Velero | **P2** | Backup engine. Outage means no *new* backups land (a growing RPO risk, not an immediate one) — restoring from the last-known-good backup is still possible until the gap grows past O3's 24h RPO bar. |
| Trivy Operator | **P2** | Continuous vulnerability/SBOM scanner. Outage stops new scan reports; it's a detection-visibility gap, not an active exploit path — no already-running workload is affected. |

**Recurrence guard:** `tests/dora-audit-readiness.bats` asserts this table exists and
names Cilium and Traefik specifically — the two components tiered P0 here,
so a future edit can't silently drop the highest-severity rows without failing
`make ci`.

**Q3. What are the recovery targets (RTO/RPO) for critical functions?**
- **Applicable?** Yes.
- **Answer:** RTO = **< 10 minutes** (O3, enforced by `make dr-restore`'s 600s budget).
  RPO = **≤ 24 hours** (Velero daily schedules, 168h retention).
- **Evidence:** [CHARTER.md](../CHARTER.md) Objective O3; [docs/DR.md](DR.md#velero-backup-restore-make-dr-restore); `gitops/velero/schedules/*.yaml`.
- **Gap:** none — CHARTER's O3 bullet now states the RPO explicitly (closed
  2026-08-07), alongside the pre-existing RTO.

**Q4. Is there a backup policy (scope, frequency, retention, and is restoration tested)?**
- **Answer:** Yes, and restoration is tested — not just assumed. `make dr-restore`
  actually restores from the latest real backup and asserts completion + timing, which
  is stronger than most personal setups (which back up but never test the restore path).
- **Evidence:** [ADR-0021](decisions/adr-0021-velero-backup-restore.md); `scripts/dr-restore.sh`.
- **Gap:** none in mechanism. Cadence gap: the test is on-demand, not scheduled (see Q9).

**Q5. Is the risk framework reviewed on a defined cadence?**
- **Answer:** Partially. ADRs get a re-evaluation log when triggered by an external
  event (e.g., ADR-0017's Vault v2.0.2 audit, resolved "keep", logged in the ADR
  itself). There's no calendar-driven review — reviews are event-triggered, not
  periodic.
- **Evidence:** ADR-0017 "Re-evaluation log" section; [ROADMAP.md:2615](../ROADMAP.md).
- **Gap:** no periodic (e.g., quarterly) re-verification that O3's RTO/RPO are still
  true on current hardware/chart versions, independent of a triggering event.

---

## Pillar 2 — Incident management, classification & reporting (Ch III)

**Q6. Is there a documented incident classification (severity) scheme?**
- **Answer:** Yes. [`docs/incident-log.md`](incident-log.md) defines a P0–P3 scheme
  sized for this lab's solo-operator, clusterless-by-default shape (blast radius →
  expected response), plus a template for logging new incidents against it.
- **Evidence:** [docs/incident-log.md](incident-log.md) "Severity scheme" section.
- **Gap:** none in scheme *existence*. The scheme covers classification, not
  automated paging/escalation — that residual gap is unchanged, see Q7.

**Q7. Is there a defined detection → escalation → resolution path?**
- **Answer:** Detection is now partly automated: Grafana Unified Alerting (RFC #1084,
  `gitops/platform/observability-grafana.yaml` `valuesObject.alerting`) evaluates six
  rules against Mimir every minute — an ArgoCD Application unhealthy for 10m+, an
  ArgoCD Application OutOfSync for 30m+, a Deployment running below its desired
  replica count for 10m+, a PVC stuck `Pending`/`Lost` for 10m+, (ROADMAP
  `auto/vault-pod-readiness-alert`) the Vault server pod not Ready for 10m+, and
  (2026-09-02, `auto/vault-sealed-degraded-alert`) Vault sealed for 10m+ even while
  its pod stays Ready — surfaced visually in Grafana's own Alerting UI. The first
  Vault rule closes this section's own previously-named gap (a real 2026-07-29
  incident, documented in `gitops/vault/unsealer.yaml`'s header comment, where
  Vault stayed sealed for 4+ days with nothing surfacing anywhere visible) using
  `kube_pod_status_ready` from the already-scraped `ksm` job, not a new
  Vault-specific scrape target — pod-readiness was the first signal closed. The
  second Vault rule (`VaultSealedDegraded`) is a direct, independent signal on
  top of it: rather than inferring seal state from the pod's readiness probe
  (whose exact behavior on a sealed-but-running Vault this remote clusterless
  session can't verify live either way, ADR-0004), it reads `vault_core_unsealed`
  straight from Vault's own telemetry — so seal state is caught whether or not
  the readiness probe happens to reflect it. Vault's own internal metrics are
  now scraped too
  (ROADMAP `auto/vault-telemetry-scrape`): a `telemetry` stanza +
  `unauthenticated_metrics_access = true` in `vault.yaml` exposes real
  `vault_core_unsealed`/`vault_core_active`/`vault_core_in_flight_requests`/
  `vault_expire_num_leases` series at `GET /v1/sys/metrics`, scraped by a new Alloy
  job and surfaced in `lab-vault.json`'s panel row (verified against Vault's own
  source, not docs prose, ADR-0004) — visual-only, same as the alerting rules below,
  not a new alert condition. There is still no escalation concept (no external
  notification receiver is configured — an **explicit non-goal**, not a silent
  absence: this is a solo-operator lab with no pager/Slack/email channel to wire one
  to, per the RFC's own reasoning). Resolution paths exist per-symptom (the cookbook).
  One real, automated signal also exists at the CI layer: `make dora-metrics`'s "time
  to restore service" row measures the wall-clock gap between a CI run going red and
  the next going green, from the real GitHub Actions API — a genuine MTTR-shaped
  metric, just scoped to CI health, not live-cluster incidents.
- **Evidence:** [docs/DR.md](DR.md#recovery-cookbook-single-component); `make status`
  target; [docs/dora-metrics.md](dora-metrics.md) "Time to restore service" row;
  `gitops/platform/observability-grafana.yaml` `valuesObject.alerting`; RFC #1084.
- **Gap:** narrower now — the "no alerting" half of this gap is closed for the six
  conditions above (as of 2026-09-02, `VaultSealedDegraded` closed the future
  candidate this section previously named: a direct, independent seal-state
  signal alongside pod-readiness, reading the already-scraped
  `vault_core_unsealed` rather than only inferring seal state from
  `kube_pod_status_ready`), and Vault's own internal telemetry is now scraped
  and dashboarded (not just pod-readiness). Remaining gaps: escalation stays a
  permanent non-goal for this solo-operator lab; the CI-health metric still
  doesn't cover a live-cluster incident.

**Q8. Are incidents logged with root cause and a corrective action, after the fact?**
- **Answer:** Yes, as of [`docs/incident-log.md`](incident-log.md)'s "Real incident
  history" table — a dedicated artifact distinct from the fix commit, capturing "what
  broke, in production-shape terms, and why" for each real incident found so far
  (root cause, fix reference, time to resolve, follow-up). `docs/done/` still records
  completed work and CLAUDE.md's bugfix rule still requires a mechanical recurrence
  guard per fix — this log is additive on top of both, not a replacement.
  `dora-metrics.md`'s change-failure-rate row remains the quantitative *how often*
  rollup; this log is the qualitative *why* for each entry.
- **Evidence:** [docs/incident-log.md](incident-log.md) "Real incident history"
  table; `docs/done/` directory; CLAUDE.md's "Every bugfix must prevent recurrence"
  section; [docs/dora-metrics.md](dora-metrics.md) "Change failure rate" row.
- **Gap:** the log currently only has entries backfilled from issue #631/#633's own
  investigation history — it isn't yet a habit enforced going forward (no mechanical
  gate requires a new row per incident, only a bats presence/shape check on the file
  itself). A future item could wire a reminder into the bugfix workflow if that gap
  proves worth closing.

**Q9. Is there a reporting timeline to a regulator for major incidents?**
- **Applicable?** No. There is no regulator and no reporting obligation.
- **Answer:** N/A by design.

---

## Pillar 3 — Digital operational resilience testing (Ch IV)

**Q10. What test types are performed, and against what?**
- **Answer:** Four distinct, real (non-fabricated) tests exist:
  1. `make dr-test` — full destroy + rebuild from code, asserts health.
  2. `make dr-restore` — restore all 4 stateful namespaces from the latest real Velero
     backup, budget-enforced.
  3. `make dr-bluegreen` — live cutover to a second cluster with a continuous uptime
     probe (proven **1135/1135**, ≥99% uptime in the last recorded run).
  4. `make capstone-demo` — end-to-end functional + tracing check, budget-enforced.
  Plus continuous vulnerability scanning (Trivy Operator) running independent of any
  `make` invocation.
- **Evidence:** [docs/DR.md](DR.md); [ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md).
- **Gap:** none in test *existence* or *honesty* of results.

**Q11. What is the testing cadence?**
- **Answer:** On-demand only, except Trivy's continuous scanning. No test above runs on
  a schedule or in CI against the live cluster (CI is clusterless by design — see
  ROADMAP rule #2 — so scheduling these against a real cluster would need a
  laptop-resident cron, which doesn't exist today).
- **Evidence:** Makefile targets; ROADMAP.md rule #2 ("You are remote and clusterless").
- **Gap:** real, but low-severity for a personal lab — the tests exist and pass when
  run; they're just not on a calendar.

**Q12. Is there an adversarial/penetration-style test (DORA's TLPT concept)?**
- **Answer:** Yes, in three scoped forms testing three different recovery
  paths/failure domains. `make dr-chaos` (`scripts/dr-chaos.sh`) kills a
  random capstone pod and asserts a replacement reaches Running within a
  120s budget, exercising Kubernetes' own ReplicaSet/Rollout self-heal.
  `make dr-network-partition` (`scripts/dr-network-partition.sh`, added
  2026-08-18) deletes capstone's ingress `NetworkPolicy` and asserts
  ArgoCD's `selfHeal` reconciliation restores it within a 300s budget,
  exercising a distinct recovery path — GitOps drift-correction rather than
  the Kubernetes controller layer. `make dr-garage-failure`
  (`scripts/dr-garage-failure.sh`, added 2026-08-18) kills the single-replica
  Garage pod (the lab's S3-compatible storage backend, ADR-0002) and asserts
  a replacement reaches Ready within a 120s budget — the same Kubernetes
  self-heal mechanism `dr-chaos` exercises, applied to the storage-layer
  failure domain this question's original framing named as still open. All
  three are *injected* failures, distinct from blue/green's *planned*
  cutover.
- **Evidence:** [docs/DR.md](DR.md#chaos--fault-injection-drill-make-dr-chaos);
  [docs/DR.md](DR.md#network-partition-drill-make-dr-network-partition);
  [docs/DR.md](DR.md#garage-failure-drill-make-dr-garage-failure);
  `scripts/dr-chaos.sh`; `scripts/dr-network-partition.sh`;
  `scripts/dr-garage-failure.sh`.
- **Gap:** narrower now — three fault types covered (a pod kill against
  capstone, a NetworkPolicy deletion against capstone, and a pod kill
  against Garage) exercising two of the lab's distinct self-heal mechanisms
  (Kubernetes controllers, ArgoCD reconciliation) across two components
  (capstone, Garage). What's still not covered: a multi-pod/quorum-loss
  scenario (not applicable today — every stateful component in this lab
  runs single-replica, per ADR-0005) and a full node-loss scenario (a
  different, larger-blast-radius failure class none of the three drills
  here attempt). This remote clusterless session authored and structurally
  verified all three scripts but has not executed any against a real
  cluster (ADR-0004 caveat, same as every other DR-script addition here).

**Q13. Are test results tracked with remediation deadlines?**
- **Answer:** Pass/fail is enforced by exit codes (CI-style), and every DR/capstone-demo
  script now also appends a row (date, status, elapsed, budget, objective) to
  [`docs/dr-results-log.md`](dr-results-log.md) on each real run, pass or fail
  (`scripts/lib/dr-results-log.sh`), so a history of *past* run results over time now
  exists, not just today's pass/fail.
- **Evidence:** `scripts/dr-restore.sh`, `scripts/dr-bluegreen.sh`, `scripts/dr-chaos.sh`,
  `scripts/capstone-demo.sh` each source `scripts/lib/dr-results-log.sh` and call
  `dr_log_result` on both their pass and fail exit paths; `docs/dr-results-log.md`.
- **Gap:** narrower now — the mechanism exists, but this remote clusterless session
  cannot generate a real logged run (ADR-0004), so the log ships with just its header;
  rows only accumulate once a maintainer or a live-cluster session actually runs one of
  the four scripts. No remediation-deadline tracking yet (out of scope here) — only a
  pass/fail/elapsed trend.

---

## Pillar 4 — ICT third-party risk management (Ch V)

**Q14. Is there a register of ICT third-party dependencies?**
- **Answer:** Yes. [`docs/dependency-register.md`](dependency-register.md) tabulates
  every third-party tool named in a binding ADR — 33 tools across 27 ADRs — by
  criticality, upstream source, deciding ADR, and last-reviewed date, re-indexed
  purely from existing ADR content.
- **Evidence:** [docs/dependency-register.md](dependency-register.md).
- **Gap:** narrower now — `make ci` gained a mechanical drift guard
  (`scripts/dependency-register-check.sh`, 2026-08-24, PR #1297, extended the same
  day in a later cycle of the same run) plus a local PostToolUse nudge hook that
  fires the same check at
  edit time (`scripts/dependency-register-sync-hook.sh`, PR #1301). It fails the
  build if any register row's "Last reviewed" date is older than the newest
  Re-evaluation-log entry of the ADR(s) cited in that row's ADR column, recognizing
  two log conventions: the `### YYYY-MM-DD` dated-heading shape most ADRs use, and
  one narrow, component-scoped slice of ADR-0034's `**YYYY-MM-DD** — <Component>
  (chart|image tag) bumped` bold-entry shape. Two honest limits remain, stated in
  the script's own header comment rather than overclaimed: (1) only 3 of the 7 rows
  citing ADR-0034 alone (kube-state-metrics, Mimir, Pyroscope) have a matching
  bold-entry pattern to check against — Alloy/node-exporter currently have no
  logged ADR-0034 entry at all, and Loki/Tempo's real currency history lives in
  ADR-0006, not ADR-0034 (cited only in the register's own prose, per the
  ADR-column-only scoping note above), so those four stay unchecked; (2) it can't
  invent a review date for an ADR that never recorded one — a few rows are still
  honestly marked "not dated in ADR" where the underlying ADR itself has no
  Re-evaluation log, which is a gap in the ADR, not something this register or its
  guard could paper over.

**Q15. Is each dependency risk-assessed (license, maintenance status, single-vendor
concentration)?**
- **Answer:** License/tier is assessed and binding ([ADR-0025](decisions/adr-0025-free-oss-tiers-only.md)).
  Maintenance status is assessed *at adoption time* (each ADR cites project maturity —
  e.g., "CNCF incubating") and, as of 2026-09-02, can also be re-checked on demand:
  `make dependency-maintenance-check` (`scripts/dependency-maintenance-check.sh`)
  walks every `docs/dependency-register.md` row's `github.com` upstream source and
  reports days since that repo's default branch last committed, flagging anything
  past a year with no commit as worth a fresh look. It is *report-only*, not wired
  into `make ci` (GitHub's request volume for a ~30-repo sweep makes it unsuitable as
  a hard, always-on gate) — so this narrows the gap from "no mechanism at all" to "a
  real mechanism that still needs a human/routine to actually invoke it", same
  category as the industry digest's own cadence.
- **Evidence:** ADR-0025; `docs/industry/2026-W23-digest.md`;
  `scripts/dependency-maintenance-check.sh`.
- **Gap:** narrower now — the re-check mechanism exists and is real (mechanical, not
  fabricated: it resolves each repo's actual last-commit date), but nothing schedules
  its invocation automatically; it depends on a future architect/janitor/executor
  cycle choosing to run it, same as `dora-metrics`.

**Q16. Is concentration risk assessed (reliance on a single upstream provider)?**
- **Answer:** Yes, as of [`docs/dependency-concentration.md`](dependency-concentration.md)
  — a cross-cutting rollup of `docs/dependency-register.md`'s 33 tools by upstream
  GitHub org. `github.com/grafana` backs six always-on-core rows at once (Grafana,
  Mimir, Loki, Tempo, Pyroscope, Alloy) — the entire observability pane sharing one
  upstream governance/maintenance entity, the largest single concentration in the
  table. `github.com/argoproj` backs two (ArgoCD, Argo Rollouts). Every other row is a
  distinct org. The lab's mitigation is structural, not new: every workload is a
  GitOps `Application` pointing at a pinned chart/image ref (ADR-0001), so a
  disappeared upstream is a fork-and-repoint operation, not a rebuild — demonstrated
  for real by the ADR-0011→ADR-0024 Artifactory→Harbor migration.
- **Evidence:** [docs/dependency-concentration.md](dependency-concentration.md);
  [docs/dependency-register.md](dependency-register.md); ADR-0001.
- **Gap:** none in rollup *existence* — the cross-cutting view this question asked for
  now exists. The `github.com/grafana` concentration itself is not closed (it's a real
  fact about upstream maintainership, not a bug this lab's code can fix); it's simply
  now visible instead of implicit.

**Q17. Is there an exit strategy per critical third-party dependency?**
- **Answer:** Yes, now pre-planned (not just implicit) for the lab's top three
  concentration risks: [`docs/dependency-exit-runbooks.md`](dependency-exit-runbooks.md)
  writes down, per group, what a real exit changes mechanically in `gitops/`, whether
  it's a fork-and-repoint or a real schema/data migration, and whether any
  alternative has actually been evaluated (honestly: no, for all three today — the
  first step of any real exit is the same ADR-writing process this lab already uses
  to pick a tool). Still grounded in ADR-0001 (GitOps + Terraform-only-bootstraps
  means every workload is redeployable by changing one `Application` source) and
  demonstrated once by the real, executed ADR-0011→ADR-0024 Artifactory→Harbor
  migration — the runbooks make the *first-response steps* explicit in advance,
  they don't replace that structural exit-ability or invent a smaller true cost.
- **Evidence:** [docs/dependency-exit-runbooks.md](dependency-exit-runbooks.md);
  ADR-0024 (executed migration); ADR-0001 (structural exit-ability).
- **Gap:** narrower still (as of 2026-09-02) — the lab's three named concentration
  groups (Q16) each have a written runbook, and so now do the four
  highest-blast-radius remaining `always-on-core` single-tool rows (Cilium, Garage,
  Traefik, cert-manager). Seven lower-blast-radius single-tool rows still
  don't (Terraform/Terragrunt, RabbitMQ, Valkey, KEDA, Forgejo,
  kube-state-metrics, node-exporter) — a real, separately-scoped future item if
  wanted. A written runbook existing in advance also doesn't mean the effort of an
  actual exit is smaller, only that the first-response steps are already
  identified — exits still happen reactively via a new ADR when actually
  triggered.

---

## Pillar 5 — Information-sharing arrangements (Ch VI)

**Q18. Is there a mechanism to receive relevant threat/operational intelligence about
the stack in use?**
- **Answer:** Designed, demonstrated, and now mechanically sustained. `docs/industry/`
  is a weekly-digest format. It produced one real entry (`2026-W23`) covering actual
  CVEs and breaking changes across the exact stack this lab runs (Vault, Valkey,
  Alloy, Envoy Gateway, Longhorn), then went silent for 9 weeks — the root cause was
  that the `news-writer` trigger's function was absorbed into
  `architect.prompt.md` STEP 1 (2026-06-13) as a research step, but that step never
  wrote its findings to `docs/industry/`, so nothing produced a new file after the
  original one-off. `routines/architect.prompt.md` STEP 1c now makes the write
  unconditional — every future architect-fallback invocation writes or refreshes the
  current ISO week's digest file regardless of whether that run finds any RFC/audit
  work — closing the gap the same way this repo's other drift classes are closed: in
  the routine's own contract, not a note to remember.
- **Evidence:** `docs/industry/2026-W23-digest.md`; `docs/industry/2026-W32-digest.md`
  (the cadence-resumption entry); `routines/architect.prompt.md` STEP 1c.
- **Gap:** the fix is structural (every architect-fallback run now writes it) but the
  architect role itself only fires when the executor's fallback chain reaches it
  (STEP 6b) — there's still no fixed calendar cadence guaranteeing a specific weekly
  fire time, only "at least as often as the fallback chain reaches this role." Given
  this repo's single-trigger, fallback-chain architecture (see `routines/routines.yaml`),
  a dedicated weekly cron for this alone would reintroduce the multi-trigger quota
  cost the 2026-06-13 consolidation deliberately removed — an acceptable trade-off
  for a personal lab, named here rather than silently assumed away.

---

## Reading this document

Sixteen of eighteen questions above have honest, evidence-backed answers grounded in
real repo state. The recurring gap pattern is **cadence, not design**: risk review,
resilience testing, dependency re-checks, and threat-intel digesting are all designed
correctly (the mechanism exists and works when invoked) but none run on a schedule —
everything is on-demand, which matches this lab being clusterless-by-default and
maintainer-triggered rather than continuously operated. **Pillar 2 (incident
classification & logging)** was the one *structural* gap, not just a cadence one —
`docs/incident-log.md` now closes the classification (Q6) and root-cause-logging (Q8)
halves of it with a real severity scheme and a backfilled incident history; the
narrower residual gap is automated detection/alerting/escalation (Q7), which remains
unchanged and is named there as an intentional non-goal for a solo-operator lab rather
than a silent absence.
