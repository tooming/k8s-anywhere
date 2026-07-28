# [Action needed] Now/next still gated; KRO/TiDB Operator/ack-s3 sweep clean, no ADR to formalize into

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles)

PR #769 (Cilium/Trivy Operator/Harbor/Kargo CVE sweep), PR #771 (ADR-0030 k3s
first audit), PR #775 (ADR-0014/0022/0024 first audits), PR #777 (ADR-0002
Garage first audit), PR #779 (ADR-0012 Istio audit-record gap closed —
ISTIO-SECURITY-2026-005 had been missed by the prior 2026-07-18 entry). Every
actively version-pinned ADR in the repo now carries at least one
Re-evaluation log entry.

## This cycle's fresh angle (sixth cycle)

Swept three on-demand components with no dedicated version-tracking ADR
(KRO, TiDB Operator, `ack-s3`) — unlike Cilium/Trivy Operator/Harbor/etc.,
there is nowhere in `docs/decisions/` to record a Keep outcome for any of
these, so this note is the only record:

- **KRO** — pinned chart `0.9.2` (`gitops/platform/kro.yaml`). Found
  CVE-2025-48710 (arbitrary-image confused-deputy RCE via
  `ResourceGraphDefinition`), affecting `<0.2.1`, fixed `0.2.1`+. Our pin
  (`0.9.2`) is many minor lines past the fix floor. Already patched.
- **TiDB Operator** — pinned chart `1.6.5` (`gitops/platform/tidb-operator.yaml`,
  on-demand). No 2026 CVE advisory found specifically naming the operator or
  this chart line (PingCAP's own security-assessment content covers TiDB the
  database engine, not concretely enough to ground a specific claim against
  this operator version per ADR-0004) — nothing actionable, not recorded as
  a finding.
- **ack-s3** — pinned chart `1.8.1` (`gitops/platform/ack-s3.yaml`, on-demand,
  AWS Controllers for Kubernetes S3 controller). No targeted CVE search
  surfaced anything specific to this controller/version; AWS ACK controllers
  are thin CRD-reconciler wrappers around the AWS SDK with a narrow attack
  surface in this lab's moto-backed (not real-AWS) usage.

No genuine gap found in any of the three, and none has an ADR to formalize a
Keep decision into (unlike the five ADRs closed out in cycles 2-5 this run) —
recording here per the same pattern as the LGTMP/ESO sweep notes (2026-07-27,
2026-07-28) that also had nowhere ADR'd to log into.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
