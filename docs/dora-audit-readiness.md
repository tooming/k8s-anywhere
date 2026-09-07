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
- **Answer:** Narrower, but simpler, than before. Every namespace this lab's
  earlier CHARTER Objective O3 named as stateful and critical — `data`, `capstone`,
  `vault`'s own Velero backup target, `tidb` — is gone: `data`/`capstone` were
  removed entirely 2026-09-07 alongside Velero/Garage (their backup mechanism),
  `tidb` was removed 2026-09-06, and `observability` the same day (ADR-0041). As
  of 2026-09-07 there is no stateful data left in this lab worth naming critical
  in the DORA sense — Vault itself holds secrets, not application state, and is
  fully re-derivable from `vault-bootstrap.sh` against a fresh cluster. The
  always-on stack is now exactly 6 namespaces (`argocd`, `cert-manager`,
  `external-secrets`, `lab-demo`, `lab-gateway`, `vault`), all load-bearing, none
  on-demand.
- **Evidence:** [CHARTER.md](../CHARTER.md) O3; [docs/dependency-tree.md](dependency-tree.md).
- **Gap:** closed below — see "Stateless component criticality tiers".

### Stateless component criticality tiers

Every always-on **stateless** component from CHARTER's "Target end-state" section,
tiered using [docs/incident-log.md](incident-log.md)'s existing P0–P3 severity scheme
(reused rather than inventing a second taxonomy) — one row per component, with a
justification grounded in what its *own* outage actually breaks, not a guess. This is
additive to Q2's existing stateful-surface answer (CHARTER O3). As of 2026-09-07
there are no on-demand heavy components left at all (Harbor and Kargo, the only two
this lab ever ran, were both removed entirely, no replacement) — every remaining
component is always-on, so there's no separate "on-demand" carve-out any more.

| Component | Tier | Why |
|---|---|---|
| Traefik | **P0** | Sole north-south ingress (ADR-0040, supersedes ADR-0008) — bundled with k3s, and (since the DR front door was removed entirely 2026-09-07, no replacement) the *only* entry point into the lab, via k3d's own load balancer on `:8080`. An outage of the gateway itself means total external unreachability — whole-lab-down by the scheme's own P0 definition. |
| k3s's bundled Flannel + kube-router | **P0** | CNI/network dataplane and NetworkPolicy enforcement — replaces Cilium (removed entirely 2026-09-07, no replacement, ADR-0014; Cilium itself was the *only* documented P0 in `docs/incident-log.md` before removal, 2026-07-29: apiserver connectivity loss, cluster-wide, caused by a stale `cilium-agent` config after every `colima start`). Without a functioning CNI no pod can reach the apiserver or any other pod. Not yet independently incident-tested since the switch (ADR-0004 caveat). |
| ArgoCD | **P1** | GitOps control plane. Already-running pods keep serving on outage — this is not immediate lab-down — but no new deploys land and drift stops self-healing, matching the P1 definition ("a single always-on component is down or degraded"). |
| Vault | **P1** | Secrets backend. Documented real incident (`gitops/vault/unsealer.yaml`'s header comment): sealed for 4+ days, silently breaking every ExternalSecrets refresh cluster-wide. Already-synced K8s `Secret` objects are untouched — new/rotated secrets stop flowing. Matches P1's "security-relevant gap" language directly. |
| External Secrets Operator | **P1** | Shares Vault's exact blast radius — the two fail together functionally (ESO is the sync mechanism, Vault is the source). |
| cert-manager | **P2** | TLS lifecycle. Existing certs keep working until their own expiry; only renewal stops — a slow-burn gap, not an immediate one. |

(Kyverno, Garage, GitLab/Forgejo, moto/ACK/KRO, Argo Rollouts, and Velero all had
rows here until they were removed entirely, no replacement, across the
2026-09-06/2026-09-07 removals — there's no outage to tier for a component that no
longer exists, same reasoning already applied to the observability stack's own
removed rows below.)

(The observability stack's own rows here — Alloy at P1, Grafana/Mimir/Loki/Tempo/
Pyroscope/kube-state-metrics/node-exporter at P2 — were removed 2026-09-06 along
with the components themselves, ADR-0041: there's no outage to tier for a
component that no longer exists.)

**Recurrence guard:** `tests/dora-audit-readiness.bats` asserts this table exists and
names Cilium and Traefik specifically — the two components tiered P0 here,
so a future edit can't silently drop the highest-severity rows without failing
`make ci`.

**Q3. What are the recovery targets (RTO/RPO) for critical functions?**
- **Applicable?** Yes, but narrower than before. Velero (this lab's only backup/restore
  mechanism) was removed entirely 2026-09-07, no replacement, alongside its S3 backend
  Garage — CHARTER Objective O3, which named this exact RTO/RPO bar, was re-scoped in
  the same change (see CHARTER.md's own note on the removal).
- **Answer:** There is no backup/restore mechanism left, so there is no RPO to state —
  a real gap, not a cadence one. The only recovery path left is a full cluster
  recreate from git (`make down && make up`); its RTO has not been independently
  timed since the 2026-09-07 simplification.
- **Evidence:** CHARTER.md's current Objective set; [docs/DR.md](DR.md);
  [ADR-0021](decisions/adr-0021-velero-backup-restore.md)'s Status.
- **Gap:** real. This lab has no data to lose (every stateful component was removed
  along with Velero/Garage — the remaining always-on stack, Vault included, is
  fully re-derivable from git + `vault-bootstrap.sh`), so the practical risk is low,
  but there is honestly no RTO/RPO commitment left to point to.

**Q4. Is there a backup policy (scope, frequency, retention, and is restoration tested)?**
- **Answer:** No. Velero — this lab's only backup/restore mechanism — was removed
  entirely 2026-09-07, no replacement, alongside its S3 backend (Garage). There is no
  backup policy and nothing to restore-test.
- **Evidence:** [ADR-0021](decisions/adr-0021-velero-backup-restore.md)'s Status.
- **Gap:** real, not just a cadence gap. Mitigated by there being no stateful data
  left in this lab worth backing up (see Q3) — everything remaining is re-derivable
  from git — but that's a property of the current small shape, not a control.

**Q5. Is the risk framework reviewed on a defined cadence?**
- **Answer:** Partially. ADRs get a re-evaluation log when triggered by an external
  event (e.g., ADR-0017's Vault v2.0.2 audit, resolved "keep", logged in the ADR
  itself). There's no calendar-driven review — reviews are event-triggered, not
  periodic.
- **Evidence:** ADR-0017 "Re-evaluation log" section; `routines/architect.prompt.md`
  STEP 2 (the source of the `## Re-evaluation log` pattern every audited/superseded
  ADR follows — a broken `ROADMAP.md:2615` line-number citation stood here until
  this fix; ROADMAP.md's own line count has since shrunk well past that line
  through this run's own legacy-item-trim batches, and the line never actually
  pointed at review-cadence content even at the time it was written — checked
  directly via `git show` against the commit that introduced it).
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
- **Answer:** Detection's automated half is gone again. From RFC #1084 (2026-09-02)
  through 2026-09-06, Grafana Unified Alerting evaluated six real rules against
  Mimir every minute (ArgoCD Application unhealthy/OutOfSync, a Deployment under
  replica count, a stuck PVC, Vault pod not-Ready, Vault sealed-but-Ready) and
  surfaced them in Grafana's own Alerting UI — see this section's own prior
  revision for the full mechanism. The observability stack that alerting ran on
  (Grafana, Mimir, and the Alloy scrape feeding both) was removed entirely with no
  replacement 2026-09-06 (ADR-0041), and no replacement alerting mechanism was
  stood up in its place — the "no alerting" gap this section had closed is open
  again, not narrower. There is still no escalation concept either (no external
  notification receiver — an **explicit non-goal** for this solo-operator lab, per
  the RFC's own reasoning, independent of the alerting-mechanism question).
  Resolution paths still exist per-symptom (the cookbook), unaffected by the
  alerting removal. One real, automated signal still exists at the CI layer:
  `make dora-metrics`'s "time to restore service" row measures the wall-clock gap
  between a CI run going red and the next going green, from the real GitHub
  Actions API — a genuine MTTR-shaped metric, just scoped to CI health, not
  live-cluster incidents.
- **Evidence:** [docs/DR.md](DR.md#recovery-cookbook-single-component); `make status`
  target; [docs/dora-metrics.md](dora-metrics.md) "Time to restore service" row;
  [ADR-0041](decisions/adr-0041-remove-observability-stack.md) (the removal that
  reopened this gap).
- **Gap:** real again, and unquantified this time — no rule-evaluation mechanism
  exists at all (not "no receiver wired to an existing evaluator," the prior
  gap's shape). A future session picking observability back up, or standing up a
  lighter-weight alternative, would need to re-close this from scratch. Escalation
  stays a permanent non-goal for this solo-operator lab regardless; the CI-health
  metric still doesn't cover a live-cluster incident.

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
- **Answer:** Narrower than before, honestly. The chaos/fault-injection drills
  (`dr-chaos`, a pod-kill against capstone), the network-partition drill
  (`dr-network-partition`), the storage-failure drill (`dr-garage-failure`),
  the Velero-restore drill (`dr-restore`), the end-to-end capstone functional
  check (`capstone-demo`), and the blue-green zero-downtime cutover drill
  (`dr-bluegreen`) all depended on components removed entirely 2026-09-07
  (capstone, Velero, Garage, the DR front door) and were deleted in the same
  change — there is no replacement for any of them. Two real tests remain:
  1. `make dr-test` — full destroy + rebuild from code, asserts health.
  2. `make dr-verify` — asserts the live lab is healthy end-to-end (no rebuild).
  No continuous vulnerability scanning exists either — Trivy Operator was
  removed entirely 2026-09-07, no replacement.
- **Evidence:** [docs/DR.md](DR.md); `scripts/dr-test.sh`; `scripts/dr-verify.sh`.
- **Gap:** real. This lab's DR testing surface shrank along with everything it used
  to exercise (backup/restore, chaos injection, blue-green cutover, continuous
  scanning) — what's left is "recreate from code, then verify," which is real and
  honest but narrower than DORA's TLPT concept asks for (see Q12).

**Q11. What is the testing cadence?**
- **Answer:** On-demand only. Neither remaining test (`dr-test`, `dr-verify`) runs on
  a schedule or in CI against the live cluster (CI is clusterless by design — see
  ROADMAP rule #2 — so scheduling these against a real cluster would need a
  laptop-resident cron, which doesn't exist today).
- **Evidence:** Makefile targets; ROADMAP.md rule #2 ("You are remote and clusterless").
- **Gap:** real, but low-severity for a personal lab — the tests exist and pass when
  run; they're just not on a calendar.

**Q12. Is there an adversarial/penetration-style test (DORA's TLPT concept)?**
- **Answer:** No, not any more. The three scoped fault-injection drills this lab used
  to run (`dr-chaos` — pod kill against capstone; `dr-network-partition` — NetworkPolicy
  deletion against capstone; `dr-garage-failure` — pod kill against Garage) each
  targeted a component removed entirely 2026-09-07 (capstone, Garage) and were
  deleted in the same change, with no replacement drill written against any
  currently-live component. This is an honest regression from a prior, narrower
  version of this answer, not a silent gap — said plainly per ADR-0004 rather than
  restating the removed drills as if they still existed.
- **Evidence:** [ADR-0021](decisions/adr-0021-velero-backup-restore.md),
  [ADR-0024](decisions/adr-0024-harbor-not-artifactory.md) Status sections (component
  removals that took the drills with them).
- **Gap:** real. A future session could write a new fault-injection drill against one
  of the six remaining always-on components (e.g. kill the single-replica ArgoCD or
  Vault pod and assert Kubernetes' own self-heal) — nothing like that exists today.

**Q13. Are test results tracked with remediation deadlines?**
- **Answer:** No mechanism exists any more. `docs/dr-results-log.md` and
  `scripts/lib/dr-results-log.sh` — the shared library every DR/capstone-demo script
  used to log a pass/fail row to — were removed 2026-09-07 alongside their last
  remaining callers (`dr-restore.sh`, `dr-chaos.sh`, `dr-network-partition.sh`,
  `capstone-demo.sh`; `scripts/lib/budget-check.sh`, the matching wall-clock-budget
  helper, went the same way). `dr-test`/`dr-verify` still enforce pass/fail via exit
  codes (CI-style), but nothing appends a historical row any more.
- **Evidence:** `scripts/dr-test.sh`, `scripts/dr-verify.sh` (exit-code enforcement).
- **Gap:** real. No remediation-deadline tracking, and no historical run log either —
  a plainer answer than the mechanism this section used to describe.

---

## Pillar 4 — ICT third-party risk management (Ch V)

**Q14. Is there a register of ICT third-party dependencies?**
- **Answer:** Yes. [`docs/dependency-register.md`](dependency-register.md) tabulates
  every third-party tool named in a binding ADR — **9 tools**, counted directly
  from the register's real rows as of 2026-09-07 (down from 13 after Cilium,
  Garage, Forgejo, Harbor, and s3manager were also removed entirely, no
  replacement, the same day and the day after Kyverno/Argo Rollouts/Velero/Trivy
  Operator/Kargo/moto/ACK/KRO went — ADR-0014, ADR-0002/ADR-0007, ADR-0035/
  ADR-0033, ADR-0024, ADR-0039 — on top of the observability stack's earlier
  8-tool removal, ADR-0041, 2026-09-06) — by criticality, upstream source,
  deciding ADR, and last-reviewed date, re-indexed purely from existing ADR
  content.
- **Evidence:** [docs/dependency-register.md](dependency-register.md).
- **Gap:** narrower now — `make ci` gained a mechanical drift guard
  (`scripts/dependency-register-check.sh`, 2026-08-24, PR #1297, extended the same
  day in a later cycle of the same run) plus a local PostToolUse nudge hook that
  fires the same check at
  edit time (`scripts/dependency-register-sync-hook.sh`, PR #1301). It fails the
  build if any register row's "Last reviewed" date is older than the newest
  Re-evaluation-log entry of the ADR(s) cited in that row's ADR column, recognizing
  the `### YYYY-MM-DD` dated-heading shape most ADRs use (the narrower,
  component-scoped `**YYYY-MM-DD** — <Component> (chart|image tag) bumped`
  bold-entry variant this check also recognized was ADR-0034's own shape, moot
  now that ADR-0034 and its rows are gone, ADR-0041). One honest limit remains,
  stated in the script's own header comment rather than overclaimed: it can't
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
  — a cross-cutting rollup of `docs/dependency-register.md`'s tools by upstream
  GitHub org. `github.com/grafana` used to back six always-on-core rows at once
  (Grafana, Mimir, Loki, Tempo, Pyroscope, Alloy) — the entire observability pane
  sharing one upstream governance/maintenance entity, the largest single
  concentration in the table — until the whole stack was removed with no
  replacement 2026-09-06 (ADR-0041); that concentration point is gone along with
  the dependency itself, the most complete resolution available.
  `github.com/pingcap` (TiDB Operator, TiDB) is gone the same way — TiDB was
  removed from the lab entirely the same day, no replacement. `github.com/argoproj`
  was the next-largest concentration (ArgoCD, Argo Rollouts) until Argo Rollouts was
  also removed entirely 2026-09-07, no replacement — argoproj now backs just ArgoCD,
  below the 2-row concentration threshold. As of 2026-09-07, no org backs 2+ rows in
  the register — there is currently no live concentration risk to name.
  Every row is a distinct org. The lab's mitigation is structural, not
  new: every workload is a GitOps `Application` pointing at a pinned chart/image ref
  (ADR-0001), so a disappeared upstream is a fork-and-repoint operation, not a
  rebuild — demonstrated for real by the ADR-0011→ADR-0024 Artifactory→Harbor
  migration.
- **Evidence:** [docs/dependency-concentration.md](dependency-concentration.md);
  [docs/dependency-register.md](dependency-register.md); ADR-0001.
- **Gap:** none in rollup *existence* — the cross-cutting view this question asked for
  now exists. The `github.com/grafana`, `github.com/pingcap`, and `github.com/argoproj`
  concentrations are all resolved (removed or dropped below threshold, not
  mitigated) — the rollup would flag a new concentration the moment one forms
  again (`make dependency-concentration-sync-check`, wired into `make ci`).

**Q17. Is there an exit strategy per critical third-party dependency?**
- **Answer:** Yes, pre-planned (not just implicit) for every dependency this lab
  actually still runs: [`docs/dependency-exit-runbooks.md`](dependency-exit-runbooks.md)
  writes down, per component, what a real exit changes mechanically in `gitops/`,
  whether it's a fork-and-repoint or a real schema/data migration, and whether any
  alternative has actually been evaluated. The `github.com/grafana` group's own
  runbook is moot (removed 2026-09-06, ADR-0041) and so are eleven more —
  Kyverno, Velero, Trivy Operator, Kargo, Harbor, moto, ACK S3 controller, KRO,
  Cilium, Garage, and Forgejo — all removed entirely 2026-09-07, no replacement,
  alongside Argo Rollouts (`github.com/argoproj`'s other former member). There's
  nothing left to plan an exit for any of those. Still grounded in ADR-0001
  (GitOps + Terraform-only-bootstraps means every workload is redeployable by
  changing one `Application` source) and demonstrated once by the real, executed
  ADR-0011→ADR-0024 Artifactory→Harbor migration (itself now also moot, Harbor
  having since been removed too) — the runbooks make the *first-response steps*
  explicit in advance, they don't replace that structural exit-ability.
- **Evidence:** [docs/dependency-exit-runbooks.md](dependency-exit-runbooks.md);
  ADR-0024 (executed migration, itself now also moot); ADR-0001 (structural
  exit-ability).
- **Gap:** none in coverage — every one of the register's 9 current rows (Q14) has
  either a written runbook or a "moot, removed" note, and
  `scripts/dependency-exit-runbooks-sync-check.sh` (wired into `make ci`) mechanically
  fails the build if a future register row lacks one. A written runbook existing in
  advance doesn't mean the effort of an actual exit is smaller, only that the
  first-response steps are already identified — exits still happen reactively via a
  new ADR when actually triggered.

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

This document was substantially rewritten 2026-09-07 after this lab's aggressive
simplification (observability, Cilium, Garage, Forgejo, GitLab, Harbor, the DR front
door, capstone, Kyverno, Argo Rollouts, Velero, Trivy Operator, Kargo, ACK, and
moto/KRO all removed, no replacement). Several answers that used to be design-complete
(Pillar 3's DR/resilience testing, Pillar 1's Q3/Q4 backup RTO/RPO) are now **real,
structural gaps, not just cadence ones** — the mechanisms that used to close them
(Velero, the chaos/network-partition/storage-failure drills, blue-green cutover, the
DR results log) were deleted along with the components they depended on, and nothing
replaces them. This is the honest current state (ADR-0004), not a temporary
regression to "fix" back to the prior answers — the maintainer's explicit direction
this session was aggressive simplification, and a smaller lab with fewer real backup
targets is a legitimate trade-off, not an oversight. What's still solid: Pillar 1's
risk-framework/criticality-tiering structure (Q1-Q2), Pillar 2's incident
classification and logging (Q6, Q8), and Pillar 4's dependency register/concentration/
exit-runbook trio (Q14, Q16, Q17), all of which stayed mechanically enforced and
accurate through the simplification. The recurring gap pattern for what remains solid
is still **cadence, not design** — reviews are event-triggered, not periodic, which
matches this lab being clusterless-by-default and maintainer-triggered rather than
continuously operated.
