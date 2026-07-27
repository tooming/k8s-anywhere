# [Action needed] Now/next still gated; fourth-cycle CVE sweep (Argo Rollouts / ESO / Garage) also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles)

- PR #759 — this run's first cycle, an `[Action needed]` record covering a
  Grafana chart bump (already merged as PR #758) plus an Artifactory
  chart-pin re-check and an O5 dashboard-coverage sweep, both clean.
- PR #762 — second cycle, ARCHITECT fallback: re-audited ADR-0009 (RabbitMQ)
  and ADR-0019 (Kyverno) against this week's CVEs. Both already patched by
  the current pins; also closed the loop on a stale flip condition from a
  prior audit (#502) that had been quietly satisfied by an unrelated routine
  bump.
- PR #765 — third cycle, ARCHITECT fallback: re-audited ADR-0028
  (cert-manager) and ADR-0029 (KEDA, first-ever audit for that ADR) against
  this week's CVEs. Both clean — cert-manager's existing flip condition still
  not triggered; KEDA's one applicable-looking CVE doesn't reach this lab's
  actual `TriggerAuthentication` config.

## This cycle's fresh angle (fourth cycle)

Continued the same architect-style CVE sweep to three more always-on/core
components not touched by the earlier cycles this run:

1. **Argo Rollouts** — found CVE-2026-35469 (a `google.golang.org/grpc`
   dependency bump, cherry-picked into the 1.9.x line). Checked
   `ADR-0020`'s own Re-evaluation log first, rather than assuming this was
   new: it's **already fully resolved** — a 2026-07-19/07-20 audit trail
   (RFC #552 + a routine upgrade-drafter bump, PR #615) already tracked this
   exact CVE through to a chart bump (`targetRevision` `2.41.0` → `2.41.1`,
   `appVersion` `v1.9.1`). Independently re-verified today: `v1.9.1`'s
   `go.mod` pins `google.golang.org/grpc v1.80.0`, past the CVE's fixed
   floor (`1.79.3`) — confirms the existing audit's conclusion, no new entry
   needed (would be pure duplication of an already-closed loop).
2. **External Secrets Operator** — CVE-2026-22822 (critical, CVSS 8.8,
   cross-namespace secret exfiltration via the `getSecretKey` template
   function, affects `0.20.2`–`<1.2.0`, fixed `1.2.0`) and CVE-2026-42876
   (privilege escalation via secret overwriting, fixed `2.4.1`). This lab's
   pin (`gitops/platform/external-secrets.yaml`, `targetRevision: 2.8.0`)
   resolves to chart `Chart.yaml` `appVersion` in the `2.7.x`–`2.8.x` range
   (verified via `raw.githubusercontent.com` at tag `v2.8.0`) — both CVEs'
   fixed floors (`1.2.0`, `2.4.1`) sit well below this. Already patched.
   ESO has no dedicated version-tracking ADR in this repo (it ships as part
   of the always-on core bundle, not its own numbered ADR), so there is no
   Re-evaluation log to append to — noted here for the record only.
3. **Garage** — WebSearch surfaced only a vague, non-specific reference to
   "two authorization bypass advisories" with no CVE identifiers resolvable
   to a concrete affected/fixed version pair, plus one clearly unrelated
   false-positive (CVE-2026-31431 "Copy Fail", a Linux-kernel AF_ALG local
   privilege-escalation bug with nothing to do with Garage — swept in by
   keyword co-occurrence, and even if real, a host-kernel concern outside
   this repo's `gitops/` control surface, not a chart/image pin). Per
   ADR-0004, an ungroundable claim is not recorded as a finding — no action,
   no ADR entry (nothing concrete enough to be either "keep" or "convert").

No new gap found this cycle. Recording it rather than silently repeating a
search that already proved empty in earlier cycles.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
