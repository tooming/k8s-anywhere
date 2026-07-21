# [Action needed] Now/next still fully gated; 2 more real PRs landed, a fresh janitor lens found a real bug

## What's blocked

Unchanged: the five remaining `[ ]` items in ROADMAP.md's *Now / next* are all
gated on issues #631/#632/#633 — re-verified this cycle, all three still
open, still zero comments (checked fresh at the end of this session).

## What this session did (picking up after cycle10)

Cycle10 (`docs/backlog/2026-07-21-action-needed-lane-gated-cycle10.md`) left
off having landed 8 real PRs and declared an unusually complete sweep. This
session started fresh (main was locally stale in the container and had to be
reset to `origin/main` first) and worked the STEP 1b/STEP 6b chain further:

- **STEP 1b recovery — PR #645.** A stale `chore/tfstate-clean-target` PR
  from a prior run was CI-green with no `[self-review]` comment posted yet —
  finished its self-review + merge before starting new work (the exact
  "PR #449" recovery scenario CLAUDE.md/executor.prompt.md call out by name).
- **Planner lens:** no ungroomed issues, `docs/roadmap/incoming/` empty,
  every 🟡 item in ROADMAP's Future section already struck through/groomed.
  Nothing to refill the lane with.
- **Architect lens:** no open `adr-audit` issues, no un-RFC'd 🟡 items. Fresh
  upstream-release sweep across the 16 architect-tracked components (via
  direct `github.com/*/releases` + Docker Hub tag fetches, since this
  session's GitHub MCP access is scoped to `tooming/k8s-anywhere` only, not
  external repos) found every one already at latest stable
  (k3s v1.36.2+k3s1, Cilium 1.17.18, Kyverno 1.18.2/chart 3.8.2, Argo
  Rollouts v1.9.1, RabbitMQ 4.3.3, Istio 1.30.3 — all confirmed current,
  matching cycles 1–10's own findings). Grafana shipped `v13.0.4` today
  (same 13.0.x line just bumped to 13.0.3) but carries no CVE fix — per
  ADR-0006's own Re-evaluation log flip condition ("a new bulletin naming
  `>= 13.0.3` as affected"), a non-CVE patch doesn't meet the bar, so
  correctly left alone (same reasoning cycle4 already applied to the 13.1.0
  minor).
- **Doc-drift-author lens:** `make ci`'s `readme-check` and `lab-ui-check`
  both clean; no broken ArgoCD `Application` source paths found via a direct
  scan of every `Application`/`ApplicationSet` `spec.source(s).path`.
- **Janitor lens → PR #646 (this session's real deliverable).** Found that
  `scripts/dora-metrics.sh` — this repo's own DORA-metrics generator —
  silently undercounts deployment frequency by ~12x when run from a shallow
  git clone, which is this script's *only* real-world calling environment
  (the remote executor always starts from one). Verified directly: this
  session's own shallow clone (51 commits, boundary at container
  provisioning time) computed "3.97 deployments/week (51 in 90d window)"
  against a true "47.67 deployments/week (613 in 90d window)" after
  unshallowing — a real ADR-0004 risk (a precise-looking but ungrounded
  number). Fixed: the script now auto-deepens a shallow clone before
  measuring, falling back to "insufficient data" (not a silently-truncated
  number) if deepening fails. New bats coverage; `docs/dora-metrics.md`
  regenerated with the real, now-correct figures. Caught and fixed a
  self-inflicted wrinkle during the same session's self-review: the first
  draft's test prose contained the literal phrase "shallow git clone",
  which tripped `scripts/git-fixture-isolation-check.sh`'s fixture-detection
  regex (a false positive, not a real bug) — reworded before landing.
  Verified zero new `make ci` failures against a clean-`main` baseline twice
  (`git stash`/`make ci`/`git stash pop`, then a final full re-run).
- **Sibling-script sweep (this cycle's fresh lens, came up empty):**
  checked every other script for the same absolute-time-window-over-a-
  possibly-shallow-clone bug class dora-metrics.sh had. Only two other
  scripts touch `git log`/`git rev-list` at all
  (`commit-reminder-hook.sh`, `rebase-open-prs.sh`) and both use ref-to-ref
  range diffs (`HEAD --not --remotes`, `merge_base..remote/main`), which are
  correct under a shallow clone as long as the two endpoints are fetched —
  no recurrence of the same bug class found.
- **Triager lens:** no untriaged open issues — the only three open issues
  are the standing #631/#632/#633 trackers, already fully labeled.

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631, #632, or #633; (b) a new upstream CVE/release firing one of the
tracked ADRs' documented flip conditions (none found this session); (c) a
new GitHub issue of any size (the planner sizes it next cycle).

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
