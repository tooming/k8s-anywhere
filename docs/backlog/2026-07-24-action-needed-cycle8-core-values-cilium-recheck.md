# [Action needed] Now/next still gated; CHARTER Core Values audit + Cilium/bats-skip recheck also clean

## What's blocked

The "Now / next" lane's remaining unchecked items are all gated on the standing
maintainer-confirmation issues #631/#632/#633 — re-verified this cycle (twelfth
cycle of this run, eighth dated cycle today): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC.

## This cycle's fresh angle

1. **CHARTER Core Values audit.** Walked every bullet under CHARTER.md's
   `## Core Values`. All map to either a mechanism already built and gated in
   `make ci` (GitOps-only deploys, recreate-from-code, stateful DR machinery,
   cloud-agnostic construction, 12 GB budget discipline, real-observability
   ADR-0004, decoupled/Garage, docs-don't-drift) or the one genuinely open item:
   "Images are signed and verified" — this is exactly O4, tracked by the two
   gated Now/next items (Enforce flip + CI rejection gate), both blocked on #631.
   No new gap found beyond what's already tracked.
2. **Cilium patch currency re-check.** `git ls-remote --tags
   https://github.com/cilium/cilium.git` confirms `v1.17.18` (the current pin,
   `gitops/platform/cilium.yaml`) is still the newest tag on the `1.17.x` line.
   No gap.
3. **`bats` conditional-skip audit.** Grepped every `tests/*.bats` file for `skip`
   calls (4 files: `cosign-bootstrap.bats`, `kyverno.bats`, `lint-script.bats`,
   `velero.bats`). All are genuinely conditional (missing binary in this sandbox,
   or a runtime file-existence check) rather than a stale permanent skip —
   specifically verified `cosign-bootstrap.bats`'s two `[ ! -f "$POLICY" ]`-gated
   tests: `gitops/kyverno/policies/verify-image-signatures.yaml` now exists in the
   repo (landed weeks ago) and both grep patterns those tests check for
   (`cosign-public-key`, `artifactory.127.0.0.1.nip.io`) are genuinely present —
   so these tests already run their real assertion in CI today, not stuck
   permanently skipping. No dead test code found.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked flip condition; (c) a new GitHub issue of any size.

This note is this cycle's honest record — on top of the eight PRs already merged
earlier in this same run (#701, #702, #703, #706, #709, #710, #711) plus three
prior `[Action needed]` notes (#712, #713, #714) — not a stopping point. The run
continues to the next cycle per `executor.prompt.md` STEP 8.
