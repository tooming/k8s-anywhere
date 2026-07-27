# [Action needed] Now/next still gated; LGTMP CVE sweep clean, no janitor target qualified

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles)

PR #758 (Grafana bump) + PR #759, PR #762 (ADR-0009/ADR-0019 CVE re-audit),
PR #765 (ADR-0028/ADR-0029 CVE re-audit), PR #766 (Argo Rollouts/ESO/Garage
sweep, clean).

## This cycle's fresh angle (fifth cycle)

**LGTMP observability stack CVE sweep** (Loki, Mimir, Tempo, Pyroscope,
Alloy — none touched by earlier cycles this run):

- **Loki**: CVE-2026-21726 (Ruler-endpoint path-traversal bypass via double
  URL encoding, fixed `>= 3.6.4`). Live image pin
  (`gitops/observability/loki/deployment.yaml`) is `grafana/loki:3.7.4` —
  already past the fix.
- **Mimir**: upstream `3.0.4` fixed a batch of Go-toolchain CVEs. Live pin
  (`gitops/observability/mimir/deployment.yaml`) is `grafana/mimir:3.1.4` —
  already past `3.0.4`.
- **Tempo**: CVE-2026-28377 (SSE-C key exposure via `/status/config`, fixed
  `< 2.10.3`) and CVE-2026-21728 (TraceQL exemplars memory-exhaustion DoS,
  fixed by 2.8/2.9/2.10's own default `max_result_limit: 262144`). Live pin
  (`gitops/observability/tempo/deployment.yaml`) is `grafana/tempo:2.10.7` —
  already past both.
- **Pyroscope**: the one 2026 CVE found is specific to the Tencent COS
  storage backend (`secret_key` leak) — this lab uses Garage S3
  (ADR-0002), not Tencent COS, so it's not applicable regardless of version.
- **Alloy**: the only lead was a container-scanner advisory bundle
  (`CLEANSTART-2026-DQ17669`) listing several CVE IDs that, on inspection,
  are generic Go-toolchain/dependency advisories already seen as false
  positives against unrelated projects earlier this run (KEDA's search
  turned up the same CVE-2026-24051/26958/33186 IDs, later confirmed
  Go-toolchain-level noise, not project-specific) — not concrete enough to
  ground per ADR-0004, so not recorded as a finding.

All five come up clean. No dedicated version-tracking ADR exists for any of
these five components (they're part of the always-on core LGTMP bundle, not
individually ADR'd), so there's nowhere to record a Re-evaluation log entry
even where a check was worth doing — noted here for the record only.

**JANITOR-lens check (STEP 6b escalation, one level further):** looked for a
bounded, behavior-preserving cleanup as the next fallback. The one candidate
considered — `scripts/adr-chart-version-sync-check.sh` and
`scripts/adr-image-pin-sync-check.sh` share a similar iterate-ADRs/extract/
compare skeleton — was rejected: the two scripts' extraction logic is
genuinely different (one reads a Helm `targetRevision` via `yq`, the other
locates a manifest from an ADR's `## Files` table and greps an `image:` line
from it), so collapsing them into a shared helper would trade a small,
readable duplication for a parameterized abstraction that's harder to follow
— exactly the premature-abstraction CLAUDE.md warns against ("three similar
lines is better than a premature abstraction"). No other footgun, monolith,
or dead-code candidate turned up on inspection (bats files are already
frozen/split per the existing `*-tests-check` guards; no untested scripts;
no doc/dashboard drift). Nothing real qualified.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
