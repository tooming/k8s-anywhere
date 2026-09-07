# Industry digest — week 2026-W37

_Period: 2026-09-07 – 2026-09-13. Written 2026-09-07 (executor's ARCHITECT-fallback
cycle, `executor.prompt.md` STEP 6b — this run's seventh cycle, when the lab still
ran its much larger prior stack). **Refreshed 2026-09-07, same ISO week, later the
same day** — a second architect-fallback invocation, this time after a large,
deliberate lab simplification (#1497) removed most of the components this entry
originally covered. Per STEP 1c's own instruction, refreshed in place rather than
creating a second file for the same week — the original entry's Argo Rollouts
dashboard CVE finding (At-a-glance/RFC #1479) is preserved below as history since it
was real, verified work that shipped (PR #1482) before the components it touched
were removed; everything else is rewritten to describe the lab's actual current,
much smaller shape._

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

---

## Lab stack

The lab's entire remaining component set, post-simplification — six always-on
namespaces, nothing on-demand. All currency facts below are cited from
`docs/dependency-register.md` directly (verified same-day by the live-cluster
session driving #1497), not re-fetched cold this cycle.

- **k3s** (`k3s-io/k3s`) — `v1.36.4+k3s1`, current (2026-09-03,
  dependency-register). ADR-0030 pins an explicit version per backend. Bundled
  Flannel CNI + kube-router NetworkPolicy controller is now the CNI (ADR-0014,
  superseded 2026-09-07 — Cilium removed, no replacement).
- **ArgoCD** (`argoproj/argo-cd`) — `v3.5.2`, full GHSA sweep clean (2026-09-03,
  dependency-register). Now syncs directly from this repo's public GitHub remote
  (Forgejo/GitLab both removed 2026-09-07, no replacement).
- **Traefik** (`traefik/traefik`, bundled with k3s per ADR-0040) — `v3.7.8` (the
  version k3s `v1.36.4+k3s1` bundles), full 9-advisory GHSA sweep clean
  (2026-09-06, dependency-register). No newer k3s release yet bundles a fixed
  Traefik; flip condition unchanged.
- **cert-manager** (`cert-manager/cert-manager`) — `v1.21.1`, full GHSA sweep
  clean (2026-09-03, dependency-register).
- **External Secrets Operator** (`external-secrets/external-secrets`) — `2.10.0`,
  full GHSA sweep clean since 2026-08-19 (dependency-register).
- **Vault** (`hashicorp/vault`) — server image `2.1.0`, no GitHub-native
  advisories exist for this repo (2026-09-03, dependency-register).

Two more register rows track opt-in/bootstrap-only tooling, not the always-on
core: **Terraform/Terragrunt** (`1.16.1`/`v1.1.4`, routine currency bump
2026-09-06) and **Oracle Cloud Infrastructure** (opt-in cloud backend, re-checked
2026-09-07 — Always Free tier terms unchanged, no live instance ever launched yet
per the `500 Out of host capacity` transient constraint CHARTER.md already
records).

---

## Ecosystem

No adjacent-project findings surfaced this cycle — this cycle's effort went into
confirming the simplification landed cleanly (`make ci` fully green on the new
`main`, zero `not ok` lines) and finding/fixing the one real doc inconsistency it
left behind (ADR-0007), rather than a cold sweep of ecosystem projects the lab no
longer depends on.

---

## For the architect

**2026-09-07 (this refresh):** CHARTER.md itself already names the one
genuinely open architectural question this simplification leaves behind: the
Oracle cloud backend's own tfstate design (`infra/live/oracle/root.hcl`, still
pointed at its own separate, still-live off-cluster Garage instance,
`infra/tfstate-oracle/`) "predates the 2026-09-07 simplification and may itself
need re-examining as a follow-up" — i.e., should the Oracle backend also drop
its Garage-based tfstate now that the local backend's equivalent is gone, or is
a genuinely separate, still-functioning instance on different infrastructure
fine to keep as-is? Not resolved in this cycle — this is exactly the kind of
concrete, scoped question a future architect-fallback cycle (or the next
architect run proper) should turn into a decision (Keep, with a flip condition,
or Convert to an RFC), rather than executor STEP 6b guessing at an architectural
call outside its lane.

No other ADR'd choice's held line was challenged by this week's real upstream
releases — the six-component always-on core is small enough that this cycle's
own re-verification (cross-checking `docs/dependency-register.md`'s dates
against real files) covered it without a fresh cold fetch.

---

## Cadence

This is the eighth entry produced under `architect.prompt.md` STEP 1c's
mandatory digest-write contract (see [2026-W36](2026-W36-digest.md)), refreshed
in place once this same ISO week per STEP 1c's own instruction rather than
creating a second file — the first refresh this cadence has needed, prompted by
a same-day change large enough (354 files, +2177/-18898 lines) to make the
morning's own entry substantially describe a stack that no longer exists by
the afternoon.
