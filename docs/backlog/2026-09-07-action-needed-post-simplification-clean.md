# [Action needed] Post-simplification re-orientation complete — repo is clean, "Now / next" genuinely empty

Follow-up to the large 2026-09-06/2026-09-07 lab simplification
([#1497](https://github.com/tooming/k8s-anywhere/pull/1497)) — a maintainer-
directed removal of most of this lab's prior component set (Cilium, Garage,
Forgejo, GitLab, Harbor, Kargo, Argo Rollouts, Velero, Trivy Operator, ACK,
moto, KRO, capstone, the DR front door), driven by a live-cluster session
with real hardware-capacity evidence (`docs/incident-log.md`'s 2026-09-06
entries: Harbor alone spiking load average to 238 and making the apiserver
unreachable on this host).

This executor run's own earlier cycles (before #1497 landed) had been
working through the pre-simplification backlog — ROADMAP legacy-item-trim
batches 7/8, several `docs/dora-audit-readiness.md`/`docs/incident-log.md`/
`docs/platform-products.md` stale-content fixes. #1497 landed mid-run,
mid-push (this session's own `chore/roadmap-legacy-item-trim-batch9` branch
had to be abandoned — pushed but not yet mergeable, based on stale content
that #1497 superseded). This note records the completed re-orientation.

## What changed underneath this run

- `docs/dependency-register.md`: 29 tools/25 ADRs → 9 rows.
- `ROADMAP.md`'s "Now / next" lane: the three items this run spent many
  cycles treating as gated (GitLab rename, GitLab decommission, capstone
  `Deployment` removal) were all closed as moot by #1497 itself — the
  components they referenced no longer exist. **Zero unchecked `- [ ]`
  items remain anywhere in ROADMAP.md.**
- Issue [#633](https://github.com/tooming/k8s-anywhere/issues/633) (the
  long-standing maintainer-confirmation gate this run tracked all cycle)
  was closed by #1497 itself, made moot the same way.

## What this cycle did after re-orienting

1. Confirmed `make ci` fully green on the new `main` (zero `not ok` lines)
   before touching anything.
2. Swept all 13 ADRs marked "Removed 2026-09-07" for internal
   contradictions (a Status paragraph claiming something the ADR's own PR
   already fixed) — found and fixed one real bug:
   [#1498](https://github.com/tooming/k8s-anywhere/pull/1498) — ADR-0007's
   Status claimed the local backend's tfstate migration off Garage was
   "not done... a separate follow-up," when #1497's own code had already
   done it in the same commit.
3. Found and closed issue
   [#1229](https://github.com/tooming/k8s-anywhere/issues/1229) as moot
   (its `.forgejo/workflows/` CI job and the CHARTER Objective O4 it
   measured are both gone) — mirrors exactly how #1497 closed #633.
   **Zero open issues remain in the repo.**
4. Refreshed `docs/industry/2026-W37-digest.md`
   ([#1499](https://github.com/tooming/k8s-anywhere/pull/1499)) — the
   entry written earlier this same run, before #1497, described a stack
   of components mostly removed a few hours later.

## What's genuinely still open (not this cycle's to solve)

CHARTER.md itself names one real, unresolved architectural question: the
Oracle cloud backend's own tfstate design
(`infra/live/oracle/root.hcl` → `infra/tfstate-oracle/`, a still-live,
separate off-cluster Garage instance, RFC #377 item 3) "predates the
2026-09-07 simplification and may itself need re-examining as a follow-up."
Correctly left for a future architect cycle to decide (Keep with a flip
condition, or Convert to an RFC) — not guessed at here.

## What would open new work

- A future architect cycle deciding the Oracle-backend tfstate question
  above.
- A new upstream release against the lab's now much smaller 6-component
  always-on core (k3s, ArgoCD, Traefik, cert-manager, External Secrets
  Operator, Vault).
- A new GitHub issue, RFC, or CHARTER edit.

This is this cycle's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
