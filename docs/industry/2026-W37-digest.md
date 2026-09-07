# Industry digest — week 2026-W37

_Period: 2026-09-07 – 2026-09-13. Written 2026-09-07 (executor's ARCHITECT-fallback
cycle, `executor.prompt.md` STEP 6b — this run's seventh cycle. The "Now / next"
lane has been fully gated for all seven cycles so far; PLANNER (cycles 2 and 6)
and JANITOR (cycle 5) fallbacks already produced real deliverables this run —
see their own `docs/done/` writeups — before the chain reached ARCHITECT here._

---

## At-a-glance

- **One `adr-audit` issue opened and resolved this cycle** (STEP 2b/STEP 2,
  same cycle — no audit outlives one): [#1478](https://github.com/tooming/k8s-anywhere/issues/1478),
  ADR-0020 (Argo Rollouts) — the Argo Rollouts **dashboard** carries a Critical,
  unpatched, unauthenticated-mutation CVE (**GHSA-366v-5xmx-36vh /
  CVE-2026-82277**, CWE-306) filed against exactly this lab's pinned appVersion
  (`v1.10.0`). Confirmed directly against GitHub's own advisory database, not a
  third-party summary. **Converted** to [RFC #1479](https://github.com/tooming/k8s-anywhere/issues/1479)
  (Traefik `basicAuth` compensating control, reusing Kargo's established
  bcrypt/Vault credential pattern) — the controller/CRDs themselves are
  unaffected, so ADR-0020's tool choice stands unchanged. Queued to
  `docs/roadmap/incoming/` for the planner to promote to "Now / next" as a 🟢
  item (the RFC is fully concrete — no further architect judgment needed).
- **No other un-RFC'd 🟡 ROADMAP item exists** (STEP 3/4 — no-op; verified: zero
  other `- [ ] 🟡` lines anywhere in ROADMAP.md this cycle).
- **Two real gaps flagged by the 2026-W36 digest are now resolved**, landed by
  earlier cycles/sessions since that digest was written (not re-actioned here,
  just reconfirmed): the Terraform-bootstrapped ArgoCD chart
  (`infra/modules/argocd/`) is now at `10.5.0`/`appVersion: 3.5.2` — the exact
  version W36 flagged as available; Argo Rollouts' chart is now at `2.43.0`/
  `appVersion: v1.10.0`, also the exact version W36 flagged. Both confirmed
  directly against the real files in this repo, not assumed from the prior
  digest's own text.
- **`routines/architect.prompt.md`'s own STEP 1 upstream-check list was stale**:
  it still named Valkey (`valkey-io/valkey`) and RabbitMQ
  (`rabbitmq/rabbitmq-server`) as components to check, even though both were
  removed from the lab entirely 2026-09-06 (ADR-0018/ADR-0009, no replacement)
  — the same class of post-removal-wave drift this run's own JANITOR-fallback
  cycle (#1476) already found and fixed in `Makefile` help text. Fixed in the
  same PR as this digest; also added **Traefik** and **Kargo**, both real
  ADR'd/always-on-or-heavy-on-demand components with their own recent dedicated
  security sweeps that had never actually been on this checklist.
- **Harbor reconfirmed current** (`v2.15.2` / chart `1.19.2`, freshly re-checked
  this cycle via GitHub's own releases page) — the oldest-dated register row
  (2026-08-20, 18 days) before this check.

---

## Lab stack

Every ADR'd component from `architect.prompt.md` STEP 1's (now-corrected)
checklist. Components checked and dated within the last 1–6 days by this run's
own earlier cycles or sibling sessions are cited from
`docs/dependency-register.md` directly per STEP 1c's own "reconfirmed current,
no new fetch needed" allowance — not re-fetched cold this cycle.

- **k3s** (`k3s-io/k3s`) — `v1.36.4+k3s1` reconfirmed newest (dependency-register,
  2026-09-03). ADR-0030 pins an explicit version per backend; no action.
- **ArgoCD** (`argoproj/argo-cd`) — `v3.5.2` reconfirmed newest (2026-09-03 full
  GHSA sweep, dependency-register). The Terraform-bootstrapped chart
  (`infra/modules/argocd/`) is now `10.5.0`/`appVersion: 3.5.2` — the W36-flagged
  gap is closed (confirmed directly against `infra/modules/argocd/variables.tf`
  and both `terragrunt.hcl` files this cycle). No action needed.
- **Cilium** (`cilium/cilium`) — `1.18.13` held (2026-09-03, dependency-register);
  ADR-0014's flip condition unfired. **Kept.**
- **Vault** (`hashicorp/vault`) — `v2.0.4`/server image `2.1.0` current
  (2026-09-03, dependency-register). No action.
- **Garage** (`deuxfleurs-org/garage`) — `v2.3.0` reconfirmed newest
  (2026-09-04, dependency-register). No action.
- **Harbor** (`goharbor/harbor-helm`) — freshly re-checked this cycle (prior
  register entry was 18 days old, the oldest active row): GitHub's own releases
  page confirms `v2.15.2` (chart `1.19.2`) is still the single newest stable
  release — no action. `docs/dependency-register.md`'s own re-check cadence for
  this row is not itself updated in this PR (that's dependency-maintenance-check
  territory, not this digest's job) — noted here for the record only.
- **Kyverno** (`kyverno/kyverno`) — chart `3.9.0`/appVersion `v1.19.0` current
  (2026-09-03, dependency-register). Also newly confirmed this run (cycle 6,
  PR #1477): the 4 `ClusterPolicy` files that don't set `failurePolicy`
  explicitly default to `Fail` per Kyverno's own controller source
  (`GetFailurePolicy()`), closing a `docs/dora-audit-readiness.md`-flagged open
  question — see that PR for the full citation. No action needed here.
- **Argo Rollouts** (`argoproj/argo-rollouts`) — chart `2.43.0`/appVersion
  `v1.10.0` is the real newest stable release (confirmed 2026-09-01, unchanged).
  **The dashboard itself has a Critical CVE** — see At-a-glance/RFC #1479. The
  core controller/CRDs are unaffected; **no chart bump needed or available**
  (no patched version exists yet).
- **Trivy Operator** (`aquasecurity/trivy-operator`) — chart `0.36.0` current
  (2026-09-01, dependency-register). No action.
- **Velero** (`vmware-tanzu/velero`) — chart `12.1.0`/appVersion `1.18.1`
  reconfirmed, full GHSA sweep clean (2026-09-03, dependency-register). No
  action.
- **Traefik** (`traefik/traefik`, bundled with k3s per ADR-0040) — newly added
  to this checklist this cycle (see At-a-glance). `v3.7.8` (the version
  k3s `v1.36.4+k3s1` bundles) had a full 9-advisory GHSA sweep just one day ago
  (2026-09-06, dependency-register/`docs/done/2026-09-06-traefik-full-ghsa-sweep.md`)
  — not re-fetched cold this cycle, that sweep is current. No action.
- **Kargo** (`akuity/kargo`) — `1.11.3` reconfirmed newest (2026-09-01,
  dependency-register). No action.
- **cert-manager** (`cert-manager/cert-manager`) — `v1.21.1` reconfirmed newest,
  full GHSA sweep clean (2026-09-03, dependency-register). No action.
- **External Secrets Operator** (`external-secrets/external-secrets`) — `2.10.0`
  current, full GHSA sweep clean since 2026-08-19 (dependency-register). No
  action.

---

## Ecosystem

No adjacent-project findings surfaced this cycle beyond the Argo Rollouts
dashboard CVE already actioned above — this cycle's research effort went into
verifying that one finding thoroughly (primary-source GHSA confirmation,
exact-pin exposure check against this lab's own manifests) rather than a broad
cold sweep of every ecosystem project, consistent with how much of the "Lab
stack" section above could honestly cite already-fresh sibling-run findings
this same week.

---

## For the architect

**2026-09-07 (this entry):** one `adr-audit` issue opened and resolved in the
same cycle (#1478 → RFC #1479, ADR-0020) — a real, Critical, currently-unpatched
CVE against this lab's exact deployed dashboard version, not a routine currency
note. `routines/architect.prompt.md`'s own STEP 1 checklist was corrected
(dropped two fully-removed components, added two real ones it had never
covered). No other ADR'd choice's held line was challenged by this week's real
upstream releases.

---

## Cadence

This is the eighth entry produced under `architect.prompt.md` STEP 1c's
mandatory digest-write contract, following [2026-W36](2026-W36-digest.md)
(written 2026-09-01, the first entry that week). This entry lands on the very
first day of ISO week 37 — the "Now / next" lane's seven-cycle gating streak
this run gave the chain unusually many opportunities to reach ARCHITECT in a
single run, which is exactly the fallback chain working as designed (STEP 6b:
"stop at the first role whose contract yields a real deliverable" — PLANNER and
JANITOR both did, twice and once respectively, before this cycle needed
ARCHITECT at all).
