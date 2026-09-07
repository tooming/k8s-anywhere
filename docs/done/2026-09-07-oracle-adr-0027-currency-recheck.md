# Oracle Cloud Infrastructure (ADR-0027) currency re-check — first review this dependency-register.md row had ever recorded

`docs/dependency-register.md`'s "Oracle Cloud Infrastructure" row was the one
remaining active row still reading "not dated in ADR (no Re-evaluation log)" —
every other active row already had a recent, dated review by this point (the
Terraform/Terragrunt row closed the prior instance of this exact gap,
2026-09-06). ADR-0027 itself has no dedicated Re-evaluation log section, so —
matching the precedent already set for the Terraform/Terragrunt and ArgoCD
(ADR-0001) rows — the review result is recorded directly in the
dependency-register.md row rather than invented into the ADR.

## What was checked

ADR-0027 documents Oracle's 2026 Always Free Ampere A1 cut (4 OCPU/24 GB → 2
OCPU/12 GB) as the basis for its "still clears ADR-0025's free/OSS-tier bar"
conclusion. Verified this is still accurate and current via a live web search:

- The cut is confirmed real, effective **2026-06-15** (Oracle applied it
  without a public announcement — multiple independent tech-press sources
  confirm the same 4/24 → 2/12 numbers ADR-0027 already states). No further
  reduction has landed since ADR-0027 was written (2026-07-13).
- **New fact found, not yet in the ADR:** Oracle has since emailed Always Free
  users that any Ampere A1 instance still exceeding the new 2 OCPU/12 GB limit
  on or after **2026-08-18** gets terminated. This is a real deadline — but
  moot for this repo today: no live Oracle k3s instance has ever actually
  launched (CHARTER.md's "Cloud backend" bullet already records the compute
  instance launch is still blocked by a transient `500 Out of host capacity`
  constraint), so there is nothing running on Oracle for this deadline to
  terminate.
- ADR-0027's core comparison (Oracle Always Free is the only option where both
  the control plane and compute genuinely clear ADR-0025's "zero spend,
  forever" bar, unlike AKS's 12-month-trial compute or GKE Autopilot's
  workload-compute billing) still holds — no competing free-tier option's
  terms have changed since.

## Outcome

No currency gap, no code/config change. `docs/dependency-register.md`'s Oracle
Cloud Infrastructure row updated with today's date and the finding above,
closing the "not dated" gap.

Found via the executor's STEP 6b fallback chain (this run's "Now / next" lane
was fully gated for a second consecutive cycle — the same PLANNER-fallback
"Now / next" pass that produced `plan/traefik-gateway-doc-drift-fix`, PR
#1472, also confirmed no new intake/architect work exists this run) — a
coverage/hardening sweep per ROADMAP rule #9's fallback-chain guidance,
checking `docs/dependency-register.md` for the oldest-reviewed/never-reviewed
row, the same lens that found the Terraform/Terragrunt gap on 2026-09-06.

## PR

https://github.com/tooming/k8s-anywhere/pull/1474 (auto/oracle-adr-0027-currency-check)
