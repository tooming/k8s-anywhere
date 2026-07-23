# [Action needed] Now/next still gated post-Kiali-fix; real cycle deliverable was PR #669, not idle

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, still zero comments, `updated_at` unchanged
since 2026-07-21.

## What this cycle actually delivered

This wasn't an idle cycle — this run's real deliverable already landed as
**PR #669** (merged): while investigating a routine "nothing actionable"
`[Action needed]` note (drafted, then abandoned before merging once this was
found), this session's own PR CI run surfaced that `gitops/platform/kiali.yaml`'s
`kiali-server` chart pin `1.89.8` (ADR-0012, the last pre-2.0 release) had
stopped resolving in the live `kiali.org/helm-charts` index — breaking
`make ci`'s `drift` job for every PR on `main`, independent of any PR's
content. Verified not transient (main's own CI passed the same check 4.5
hours earlier). Opened RFC #668 (architect-fallback role, since ADR-0012
explicitly pins the dead version — a binding-ADR change needs a decision
first per CLAUDE.md), verified Kiali 2.0's real breaking changes don't touch
this lab's `valuesObject`, and landed the ADR-0012 audit entry + the actual
chart bump to `2.29.0` + doc/test updates together in one PR (justified in
the PR body: splitting decision from implementation wasn't viable here since
*any* second PR would inherit the same pre-existing red check). Self-reviewed
(gate integrity / ADR compliance / fabricated content / alternatives /
ADR-conflict / CHARTER-bound / reversibility), merged. `main` is CI-green
again as of this commit.

## This cycle's sweep (post-fix), also empty

- **Planner:** no ungroomed issues beyond the three standing trackers;
  `docs/roadmap/incoming/` empty.
- **Architect:** re-walked every ADR's `## Re-evaluation log` flip condition
  — none newly fired beyond the Kiali one just actioned.
- **Upgrade-drafter (fresh angle — plain-image pins outside Helm charts):**
  grepped `gitops/platform/*.yaml` + `gitops/moto/` + `gitops/ack*/` for raw
  `image:` pins not gated by `helm-chart-pin-check.sh` (that script only
  verifies chart `targetRevision`, not a chart's embedded image tag override).
  Found two: `docker.io/grafana/grafana:13.0.3` (bumped last cycle, still
  current) and `motoserver/moto:5.2.2` (confirmed still the latest published
  tag). Neither needs action.
- **Doc-drift:** `make ci` clean post-merge (verified via a fresh
  `git pull --ff-only` + local `make ci` run).
- **Triager:** all three open issues already fully labeled.
- **Janitor:** no new untested script found this pass.

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631, #632, or #633; (b) a new upstream CVE/release firing a tracked ADR
flip condition; (c) a new GitHub issue of any size.

This note is this cycle's honest record — the *previous* cycle's real
deliverable was PR #669, not this note. The run continues to the next cycle
per `executor.prompt.md` STEP 8.
