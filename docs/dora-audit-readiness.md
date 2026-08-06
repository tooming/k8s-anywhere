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
- **Answer:** Yes, for the stateful surface. CHARTER Objective O3 names the six
  stateful namespaces (`data`, `tidb`, `capstone`, `vault`, `observability`,
  `inkless`) as critical; the always-on
  vs. on-demand split (12GB budget, ADR-0003) documents which ~58 Applications are
  load-bearing (re-counted 2026-07-29, issue #846 — CHARTER's own "Always-on core"
  bullet count is ~33 of those 58; the rest are the always-on next-wave/cert-manager/
  KEDA/capstone Applications, distinct from the ~5 namespace-only PSA-floor shells
  that merely pre-stage an otherwise on-demand heavy component).
- **Evidence:** [CHARTER.md](../CHARTER.md) O3; [docs/dependency-tree.md](dependency-tree.md).
- **Gap:** no equivalent criticality tiering for the *stateless* surface (e.g., is
  Envoy Gateway more critical than Kiali? Implicit from always-on/on-demand split, never
  stated as a tier).

**Q3. What are the recovery targets (RTO/RPO) for critical functions?**
- **Applicable?** Yes.
- **Answer:** RTO = **< 10 minutes** (O3, enforced by `make dr-restore`'s 600s budget).
  RPO = **≤ 24 hours** (Velero daily schedules, 168h retention) — true today but never
  labeled "RPO" anywhere in the docs before this file.
- **Evidence:** [docs/DR.md](DR.md#velero-backup-restore-make-dr-restore); `gitops/velero/schedules/*.yaml`.
- **Gap:** RPO isn't named as a target anywhere else — CHARTER only states the RTO.
  Cheap fix: add an explicit RPO line to O3 in CHARTER.md.

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
- **Answer:** Detection is manual (`make status`, Grafana dashboards, `make dr-verify`)
  — nothing pages or alerts automatically. Resolution paths exist per-symptom (the
  cookbook), but there's no escalation concept since there's no one to escalate to.
  One real, automated signal now exists at the CI layer: `make dora-metrics`'s "time to
  restore service" row measures the wall-clock gap between a CI run going red and the
  next going green, from the real GitHub Actions API — a genuine MTTR-shaped metric,
  just scoped to CI health, not live-cluster incidents.
- **Evidence:** [docs/DR.md](DR.md#recovery-cookbook-single-component); `make status`
  target; [docs/dora-metrics.md](dora-metrics.md) "Time to restore service" row.
- **Gap:** no alerting (Grafana has dashboards, not alert rules, as far as this repo's
  gitops/ shows); no escalation path (N/A for a solo operator, but worth naming as an
  explicit non-goal rather than a silent absence); the CI-health metric doesn't cover a
  live-cluster incident (e.g., Vault sealed, Garage unreachable) — those still have no
  automated detection-to-resolution timer.

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
- **Answer:** Yes, in a scoped form. `make dr-chaos` (`scripts/dr-chaos.sh`) kills a
  random capstone pod and asserts a replacement reaches Running within a 120s
  budget — an *injected* failure, distinct from blue/green's *planned* cutover.
- **Evidence:** [docs/DR.md](DR.md#chaos--fault-injection-drill-make-dr-chaos);
  `scripts/dr-chaos.sh`.
- **Gap:** narrower now — this covers one fault type (a single pod kill) against
  one component (capstone). Cutting a NetworkPolicy or simulating Garage
  unavailability, as this question's original framing suggested, are still real,
  separately-scoped future drills if wanted. This remote clusterless session
  authored and structurally verified the script but has not executed it against a
  real cluster (ADR-0004 caveat, same as every other DR-script addition here).

**Q13. Are test results tracked with remediation deadlines?**
- **Answer:** Pass/fail is enforced by exit codes (CI-style), but there's no historical
  log of *past* run results over time — only the current pass/fail, not a trend.
- **Evidence:** `scripts/dr-restore.sh`, `scripts/capstone-demo.sh` exit-code behavior.
- **Gap:** minor — a results log would let you see if the 10-minute RTO is trending up
  as the lab grows, not just whether it passed today.

---

## Pillar 4 — ICT third-party risk management (Ch V)

**Q14. Is there a register of ICT third-party dependencies?**
- **Answer:** Yes. [`docs/dependency-register.md`](dependency-register.md) tabulates
  every third-party tool named in a binding ADR — 22 tools across 20 ADRs — by
  criticality, upstream source, deciding ADR, and last-reviewed date, re-indexed
  purely from existing ADR content.
- **Evidence:** [docs/dependency-register.md](dependency-register.md).
- **Gap:** the register has no mechanical drift guard yet — it's a manual snapshot
  that can go stale as future ADR bumps land without a matching register update (the
  file says so explicitly, rather than implying a freshness guarantee that doesn't
  exist). Several dates are honestly marked "not dated in ADR" rather than guessed,
  since a number of ADRs never stated an explicit decision date to begin with — that
  gap is in the ADRs themselves, not something this register could invent its way
  around.

**Q15. Is each dependency risk-assessed (license, maintenance status, single-vendor
concentration)?**
- **Answer:** License/tier is assessed and binding ([ADR-0025](decisions/adr-0025-free-oss-tiers-only.md)).
  Maintenance status is assessed *at adoption time* (each ADR cites project maturity —
  e.g., "CNCF incubating") but not re-checked afterward except when a breaking change is
  independently noticed (the `docs/industry/` digest).
- **Evidence:** ADR-0025; `docs/industry/2026-W23-digest.md`.
- **Gap:** no scheduled re-check of maintenance health (is the project still active,
  still maintained) after initial adoption.

**Q16. Is concentration risk assessed (reliance on a single upstream provider)?**
- **Answer:** Assessed per-decision (each ADR names rejected alternatives, which is
  itself an anti-concentration exercise) but never rolled up into a single
  cross-cutting view of "which single upstream repo, registry, or chart source, if it
  disappeared, would break the most components at once."
- **Evidence:** ADR set (per-decision only).
- **Gap:** real; a genuinely new artifact, not just re-indexing — lowest priority of the
  gaps in this document since the lab's answer to any single-provider disappearing is
  already "fork or replace the chart, GitOps handles the rest" (ADR-0001's design).

**Q17. Is there an exit strategy per critical third-party dependency?**
- **Answer:** Implicit in ADR-0001 (GitOps + Terraform-only-bootstraps means every
  workload is redeployable by changing one `Application` source) and demonstrated by
  the ADR-0011→ADR-0024 Artifactory→Harbor migration itself (a real, executed exit from
  one provider to another). No dependency has a *written* exit runbook in advance of
  needing one.
- **Evidence:** ADR-0024 (executed migration); ADR-0001 (structural exit-ability).
- **Gap:** minor — exits happen reactively (via a new ADR) rather than being
  pre-planned per critical dependency.

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
