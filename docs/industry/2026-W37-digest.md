# Industry digest — week 2026-W37

_Period: 2026-09-07 – 2026-09-13. Written 2026-09-07 (executor's ARCHITECT-fallback
cycle, `executor.prompt.md` STEP 6b — this run's seventh cycle, when the lab still
ran its much larger prior stack). Refreshed 2026-09-07, same ISO week, later the
same day — a second architect-fallback invocation, this time after a large,
deliberate lab simplification (#1497) removed most of the components this entry
originally covered. **Refreshed again 2026-09-12, same ISO week** — a third
architect-fallback invocation (`executor.prompt.md` STEP 6b, reached with a fully
exhausted "Now / next" lane: zero unchecked ROADMAP items, zero open issues, zero
un-RFC'd 🟡 items) — the 2026-09-07 refresh had itself gone stale within the same
week: it still listed Vault + External Secrets Operator as two of the "six
always-on" components, but both were removed entirely a few hours *after* that
refresh was written (ADR-0042, same day); it also left the Oracle-backend tfstate
question in "For the architect" marked unresolved when ADR-0007's own
Re-evaluation log had in fact resolved it (Keep, unchanged) that same day. Per
STEP 1c's own instruction, refreshed in place again rather than creating a second
file for the same week — the original entry's Argo Rollouts dashboard CVE finding
(At-a-glance/RFC #1479) is preserved below as history since it was real, verified
work that shipped (PR #1482) before the components it touched were removed;
everything else now describes the lab's actual current, four-namespace shape._

---

## At-a-glance

- **A large, deliberate lab simplification landed today** (#1497, maintainer
  direction, following real host-capacity evidence — see `docs/incident-log.md`'s
  2026-09-06 entries): Cilium, Garage (+ s3manager + its off-cluster tfstate
  instance), Forgejo (+ GitLab before it), Harbor, the DR front door + blue/green
  drill, capstone, Kyverno, Kargo, Argo Rollouts, Velero, Trivy Operator, and
  ACK/moto/KRO were all removed entirely, **no replacement**. `docs/dependency-
  register.md` shrank from 29 tools/25 ADRs to 9 rows (one, Cilium, kept as an
  explicit "removed" historical row rather than deleted, since ADR-0014's own
  Re-evaluation log needed somewhere to anchor the finding). CHARTER.md's
  Objectives O1/O3/O4/O6 were all retired the same day — see CHARTER.md's own
  "The 2026-09-07 simplification" section for the full rationale.
- **This entry's original finding (this morning, before the simplification) is
  preserved as history, not retracted**: one `adr-audit` issue
  ([#1478](https://github.com/tooming/k8s-anywhere/issues/1478)) found the Argo
  Rollouts dashboard carrying a Critical, unpatched, unauthenticated-mutation CVE
  (**GHSA-366v-5xmx-36vh / CVE-2026-82277**). Converted to
  [RFC #1479](https://github.com/tooming/k8s-anywhere/issues/1479) and shipped as a
  Traefik `basicAuth` compensating control (PR #1482) the same day, before Argo
  Rollouts itself was removed entirely a few hours later in #1497. The fix was real,
  verified, correctly-scoped work at the time it landed — it just no longer applies
  to anything, since its subject component is gone.
- **`routines/architect.prompt.md`'s own STEP 1 upstream-check list was already
  corrected by #1497 itself** — it now lists only the six components this lab
  actually still runs (k3s, ArgoCD, Vault, Traefik, cert-manager, External Secrets
  Operator), down from the much longer list this entry's own upstream sweep used
  this morning. No further action needed here.
- **Issue #633 closed as moot by #1497** (Harbor/Kargo/Argo Rollouts, the
  components #633 asked to verify a canary+promotion cycle against, no longer
  exist). **Issue #1229 closed as moot in this cycle** (its `.forgejo/workflows/`
  CI job and the O4 objective it measured are both gone — `.forgejo/` itself no
  longer exists in the repo, confirmed directly).
- **One real, verified doc bug found and fixed in this cycle**: ADR-0007's own
  Status paragraph (written as part of #1497) claimed the local backend's
  Terraform-state migration off Garage was "not done... a separate follow-up" —
  wrong the moment it was written, since #1497's own code already migrated
  `infra/live/local/root.hcl` to a local backend in the same change. Fixed in
  [docs/done/2026-09-07-adr-0007-status-stale-migration-claim-fix.md](../done/2026-09-07-adr-0007-status-stale-migration-claim-fix.md)
  (PR #1498).
- **2026-09-12 refresh: Vault + External Secrets Operator removed entirely,
  same day as the entry above, no replacement** (ADR-0042, superseding
  ADR-0036/ADR-0037) — by the time they were cut, ESO had zero live
  `ExternalSecret` consumers left in the repo, since every component that had
  ever needed a Vault-held credential (Garage, Harbor, Kargo, Velero, ACK,
  capstone) was already gone from #1497 earlier the same day. The always-on
  core this digest's "Lab stack" section describes below has been four
  namespaces (ArgoCD, cert-manager, Traefik/`lab-gateway`, `lab-demo`) since
  that removal, not the six this entry originally listed.
- **2026-09-12 refresh: CHARTER Objective O7 (DORA metrics) shipped 2026-09-11**
  — `make dora-metrics` computes deployment frequency, lead time, change failure
  rate, and time-to-restore from real git/CI history into `docs/dora-metrics.md`
  (RFC #580), ahead of its 2026-10-31 bar. O2 (default-deny + PSS-restricted
  everywhere, due 2026-09-30) remains on track — `make ci`'s
  `tests/networkpolicy-*.bats` + `tests/securitycontext-*.bats` cover all four
  current namespaces, verified directly this cycle.
- **2026-09-12 refresh: a new fault-injection drill landed 2026-09-11**
  (`scripts/dr-chaos-argocd.sh` / `make dr-chaos-argocd`, `docs/done/2026-09-11-
  dr-chaos-argocd.md`) — kills the single-replica ArgoCD application-controller
  pod and asserts Kubernetes' own self-heal + every `Application` returning to
  Synced+Healthy, closing the `docs/dora-audit-readiness.md` Q12 gap the prior
  three chaos drills left behind when their targets (capstone, Garage) were
  removed 2026-09-07 with no replacement.

---

## Lab stack

The lab's entire remaining component set — four always-on namespaces, nothing
on-demand, since Vault + External Secrets Operator were removed 2026-09-07
(ADR-0042, see At-a-glance above) — the six-component list this entry
originally described no longer matches the repo. All currency facts below are
cited from `docs/dependency-register.md` directly; the four version pins were
independently re-verified live this cycle (`git ls-remote --tags` against each
upstream, 2026-09-12) rather than trusted cold from the register.

- **k3s** (`k3s-io/k3s`) — `v1.36.4+k3s1`, still the newest stable tag as of
  2026-09-12 (`v1.37.0` remains at `-rc5`, no stable cut yet). ADR-0030 pins an
  explicit version per backend. Bundled Flannel CNI + kube-router NetworkPolicy
  controller is now the CNI (ADR-0014, superseded 2026-09-07 — Cilium removed,
  no replacement).
- **ArgoCD** (`argoproj/argo-cd` chart via `argoproj/argo-helm`) — chart
  `10.9.0` (bumped from `10.8.4` 2026-09-11, packaging-only, appVersion
  unchanged at `v3.5.2`), confirmed still the newest chart tag as of 2026-09-12.
  Full GHSA sweep clean as of 2026-09-03. Syncs directly from this repo's public
  GitHub remote (Forgejo/GitLab both removed 2026-09-07, no replacement).
- **Traefik** (`traefik/traefik`, bundled with k3s per ADR-0040) — `v3.7.8` (the
  version k3s `v1.36.4+k3s1` bundles), full 9-advisory GHSA sweep clean
  (2026-09-06, dependency-register). No newer k3s release yet bundles a fixed
  Traefik; flip condition unchanged, re-confirmed live 2026-09-11 and again
  2026-09-12.
- **cert-manager** (`cert-manager/cert-manager`) — `v1.21.2` (bumped from
  `v1.21.1` 2026-09-11: fixes an ACME response-body info-disclosure issue, an
  unbounded-response-body DoS vector, and a validating-webhook panic),
  confirmed still the newest stable tag as of 2026-09-12.

Two more register rows track opt-in/bootstrap-only tooling, not the always-on
core: **Terraform/Terragrunt** (`1.16.2`/`v1.1.4` — Terraform bumped from
`1.16.1` 2026-09-11, a single upstream panic fix, no CVE; both re-confirmed
current live 2026-09-12) and **Oracle Cloud Infrastructure** (opt-in cloud
backend, re-checked 2026-09-07 — Always Free tier terms unchanged, no live
instance ever launched yet per the `500 Out of host capacity` transient
constraint CHARTER.md already records).

---

## Ecosystem

No adjacent-project findings surfaced this cycle either — GitHub API access
(release notes, GHSA search) was unavailable to this remote session beyond
anonymous `git ls-remote --tags` against each upstream's own repo, so this
cycle's currency check is scoped to "is a newer stable tag published" (it
isn't, for any of the four pinned sources above) rather than a fresh GHSA
sweep. No new GHSA was surfaced against `v3.7.8` (Traefik), `v1.36.4+k3s1`
(k3s), the ArgoCD chart's `v3.5.2` appVersion, or cert-manager past `v1.21.2`
this cycle.

---

## For the architect

**2026-09-12 refresh: the 2026-09-07 open question is resolved, not still
open.** The prior refresh of this entry (written earlier the same day as
ADR-0007's own Re-evaluation log entry, but before it) flagged whether the
Oracle cloud backend's own tfstate design (`infra/live/oracle/root.hcl`, its
own separate off-cluster Garage instance, `infra/tfstate-oracle/`) should also
be reconsidered now that the local backend's equivalent Garage was removed.
Checked directly this cycle: ADR-0007's "Re-evaluation log" section already
records a terminal **Keep, unchanged** decision dated 2026-09-07 — the two
removals had non-transferable reasons (the local instance's *consumers* all
disappeared and the local host was capacity-constrained; the Oracle instance
serves a durable cross-session state need that never went away and runs on its
own, separate Always Free instance with no shared capacity pressure) — with an
explicit flip condition (the Oracle backend itself is ever removed, or Oracle's
own object storage becomes a viable direct Terraform S3-compatible backend).
Nothing left open here; this digest's own staleness on the point (five days,
same ISO week) is itself the finding worth naming for future refreshes: a
"For the architect" open question should be checked against the ADR's own
Re-evaluation log before being re-asserted as still-open, not just repeated
from the prior refresh.

No other ADR'd choice's held line was challenged this cycle — the four-item
always-on core is small enough that direct re-verification (cross-checking
`docs/dependency-register.md`'s dates against real files, plus this cycle's own
live `git ls-remote` re-checks above) covered it fully. No 🟡 ROADMAP item is
without an RFC (zero 🟡 items remain un-struck anywhere in ROADMAP.md, checked
directly), and no `adr-audit`-labeled issue is open — this lane has nothing to
close or convert this cycle.

---

## Cadence

This is the ninth entry produced under `architect.prompt.md` STEP 1c's
mandatory digest-write contract (see [2026-W36](2026-W36-digest.md)), refreshed
in place a second time this same ISO week per STEP 1c's own instruction rather
than creating a second file — reached via `executor.prompt.md` STEP 6b with a
fully exhausted "Now / next" lane (zero unchecked ROADMAP items, zero open
GitHub issues, `make ci` fully green with zero drift signals) after the
PLANNER fallback found no gap to promote and no issue to groom.
