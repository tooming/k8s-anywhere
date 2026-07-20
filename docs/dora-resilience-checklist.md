# DORA-shaped resilience checklist

**Scope note.** This borrows the *structure* of the EU Digital Operational Resilience
Act (Regulation (EU) 2022/2554) as a checklist for writing resilience-minded
Objectives — it does not mean the lab is, or needs to be, DORA-compliant. DORA applies
to regulated financial entities and their critical ICT third-party providers; a
personal learning lab is neither. See
[docs/dora-audit-readiness.md](dora-audit-readiness.md) for a companion Q&A template
that answers the kind of questions a DORA audit would ask, for anyone who wants
practice articulating this lab's posture in that language.

DORA organizes ICT resilience into five pillars (Ch II–VI of the regulation). Each
pillar below is restated as a **checklist a resilience-minded Objective should satisfy**
— control the Objective should name, target metric, evidence source, review cadence —
then scored against CHARTER's current **O3** ("Stateful DR is exercised") and the rest
of the lab's resilience surface, so the checklist is validated against something real
rather than left abstract.

---

## 1. ICT risk management (DORA Ch II)

**What the checklist asks:**
- Are critical functions/assets identified and mapped?
- Is there a stated recovery target (RTO/RPO) per critical function?
- Is there a backup policy (what's backed up, how often, how long retained)?
- Is protection/prevention (not just recovery) addressed — least privilege, network
  segmentation, admission control?
- Is the framework reviewed on a defined cadence, not just written once?

**Lab status:**
| Item | Status | Evidence |
|---|---|---|
| Critical namespaces identified | ✅ | `data`, `tidb`, `capstone`, `vault` named explicitly in CHARTER O3 |
| RTO stated | ✅ | O3: restore in **< 10 min** wall-clock ([CHARTER.md:121](../CHARTER.md)) |
| RPO stated | ✅ (implicit) | Velero schedules are daily (`0 2/30 2/0 3/30 3 * * *`), TTL 168h → **RPO ≤ 24h** — real but never named as "RPO" anywhere in the docs |
| Backup policy documented | ✅ | [ADR-0021](decisions/adr-0021-velero-backup-restore.md), schedule table in [docs/DR.md](DR.md) |
| Prevention/protection controls | ✅ | ADR-0016 (default-deny NetworkPolicy), ADR-0017 (PSS restricted), ADR-0019 (Kyverno admission) |
| Review cadence for the framework itself | ❌ **gap** | No recurring "re-verify O3 is still true" cadence exists — `make dr-restore` is a script you can run, but nothing runs it periodically or tracks when it was last actually exercised live |

**Checklist takeaway:** name the RPO explicitly (it already exists implicitly in the
Velero schedule — it just isn't called that anywhere), and add a review-cadence line to
whatever Objective covers this ("re-run `make dr-restore` and record the result at
least every N days/before every ADR-0021-touching change").

---

## 2. ICT-related incident management, classification & reporting (DORA Ch III)

**What the checklist asks:**
- Is there a severity/classification scheme for incidents?
- Is there a defined detection → escalation → resolution path?
- Is there a target time-to-acknowledge / time-to-resolve per severity?
- Are incidents logged with root cause, not just fixed and forgotten?

**Lab status:**
| Item | Status | Evidence |
|---|---|---|
| Recovery runbook | ✅ (partial) | "Recovery cookbook" in [docs/DR.md](DR.md#recovery-cookbook-single-component) — Vault sealed, GitLab down, ArgoCD out of sync, Grafana dashboards missing |
| Severity classification | ❌ **gap** | No severity tiers exist (P0/P1/P2 or equivalent); the runbook doesn't distinguish "whole lab down" from "one dashboard stale" |
| Detection mechanism | ⚠️ partial | Grafana dashboards + `make status`/`make dr-verify` give visibility, but nothing pages or alerts — detection is "you notice", not automated |
| Root-cause logging | ❌ **gap** | `docs/done/` records *what shipped*, not *what broke and why* — there's no postmortem/incident-log directory |
| Reporting timeline to an authority | N/A | No regulator; not applicable to a personal lab |

**Checklist takeaway:** this is the pillar with the biggest real gap. CLAUDE.md's
bugfix-must-prevent-recurrence rule already captures the *fix* side; what's missing is
the *classification and log* side — a lightweight `docs/incidents/` (mirroring
`docs/done/`) with severity + root cause + guard added, so recurring failure modes are
visible over time instead of only fixed one at a time.

---

## 3. Digital operational resilience testing (DORA Ch IV)

**What the checklist asks:**
- What test types exist (vulnerability scans, scenario/failover tests, performance
  tests, end-to-end tests)?
- What's the cadence — on-demand only, or scheduled?
- Is there an advanced/adversarial test (DORA's Threat-Led Penetration Testing, for
  critical systems, every 3 years)?
- Are results tracked with remediation deadlines?

**Lab status:**
| Item | Status | Evidence |
|---|---|---|
| Continuous vulnerability scanning | ✅ | Trivy Operator, [ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md) |
| Scenario/failover test | ✅ | `make dr-test`, `make dr-bluegreen` — [docs/DR.md](DR.md), proven **≥99% uptime, 1135/1135 probes** across a real cutover |
| Backup-restore test | ✅ | `make dr-restore`, budget-enforced (<600s) |
| End-to-end functional test | ✅ | `make capstone-demo`, budget-enforced (<900s) |
| Admission/supply-chain rejection test | 🟡 planned, not live | `verify-image-rejection` CI job — [ROADMAP.md:1764](../ROADMAP.md), blocked on the cosign-enforce gate |
| Scheduled cadence (vs. on-demand only) | ❌ **gap** | Every test above is a `make` target a human runs manually; none are on a cron. Trivy Operator is the one exception (its scans are continuous by design) |
| Adversarial/pentest-style test | ❌ **gap** | No chaos-engineering or fault-injection scenario exists (e.g., kill a pod mid-request, sever a NetworkPolicy, simulate Garage unavailability) — the closest thing is the blue/green cutover, which tests planned failover, not injected failure |

**Checklist takeaway:** the lab actually scores well here — it's the strongest pillar.
The two real gaps (no scheduled cadence, no injected-failure test) are legitimate
future ROADMAP candidates if you want to close them, not urgent.

---

## 4. ICT third-party risk management (DORA Ch V)

**What the checklist asks:**
- Is there a register of every third-party ICT dependency?
- Is each dependency risk-assessed (maintenance status, license, single-vendor
  concentration)?
- Is there an exit strategy per critical dependency?

**Lab status:**
| Item | Status | Evidence |
|---|---|---|
| Dependency decisions recorded | ✅ | 29 ADRs in `docs/decisions/`, each naming the chosen tool + rejected alternatives + why |
| License/tier verified free | ✅ | [ADR-0025](decisions/adr-0025-free-oss-tiers-only.md) — binding, checked before adoption |
| CVE/breaking-change tracking per dependency | ⚠️ started, not sustained | `docs/industry/2026-W23-digest.md` — one week's digest exists, format is right, cadence isn't |
| Consolidated register (name, criticality, last-reviewed date) | ❌ **gap** | The ADRs are decision *records*, not an enumerated, queryable inventory — there's no single table of "29 dependencies, each with a criticality tier and last-reviewed date" |
| Concentration-risk view | ⚠️ partial | ADR-0002/0018/0024 etc. show *rejected* alternatives (so single-vendor lock-in was considered per-decision), but there's no cross-cutting view of "which single upstream repo/registry, if it disappeared, would break the most things" |

**Checklist takeaway:** the ADR set is doing most of the work DORA would want here, just
not indexed as a register. A `docs/dependency-register.md` (one row per ADR: tool,
criticality, upstream source, last-reviewed) would close most of this gap cheaply, by
tabulating information that already exists rather than gathering anything new.

---

## 5. Information-sharing arrangements (DORA Ch VI)

**What the checklist asks:**
- Is there a defined channel/cadence for receiving relevant threat intelligence about
  the stack in use?

**Lab status:**
| Item | Status | Evidence |
|---|---|---|
| Threat/CVE intel intake exists in concept | ✅ | `docs/industry/` digest format |
| Sustained cadence | ❌ **gap** | Only one digest (`2026-W23`) exists; no recurring routine produces the next one |

**Checklist takeaway:** the mechanism is designed, just not running. Lowest-effort
pillar to close if you want it — it's a cadence problem, not a design problem.

---

## Summary — what a DORA-shaped resilience Objective should specify

Whether this becomes a new CHARTER Objective or a tightened O3, the checklist this
exercise produces is: for each of the five pillars, name **(a)** the control, **(b)**
the target metric, **(c)** the evidence source that proves it's true, and **(d)** the
review cadence. Scored against that:

- **Pillar 1 (risk mgmt)** and **Pillar 3 (testing)** — already strong; mostly missing
  explicit RPO language and a scheduled cadence.
- **Pillar 2 (incident mgmt)** — the real gap: no severity scheme, no incident log.
- **Pillar 4 (third-party risk)** — existing ADRs just need indexing into a register.
- **Pillar 5 (info sharing)** — designed, not sustained; a cadence fix.

None of this requires becoming DORA-compliant (out of scope, not applicable) — it's
useful purely as a rubric for what "resilience is exercised" should mean beyond the
current single metric (O3's 10-minute restore number).
