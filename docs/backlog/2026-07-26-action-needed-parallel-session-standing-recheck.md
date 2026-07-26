# [Action needed] Now/next still gated; standing issues still unconfirmed

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, `updated_at` unchanged since
2026-07-21T05:34 UTC. `list_issues` (state=OPEN) confirms these three remain
the only open issues in the repo.

## Note on concurrent execution

This cycle discovered that a second, independently-scheduled executor
session (`session_01RgBVjiz5wH5uMCmWXHqiMJ`) has been running against this
same repo in parallel with this one, producing real merged work this run
hadn't seen: PR #745 (first full local `make ci` toolchain install —
bats/kustomize/kubeconform/helm/terraform, confirming main is green top to
bottom), PR #746 (confirmed `registry.terraform.io` is proxy-blocked in that
session's sandbox, same as the Helm chart-index hosts, validating the
existing skip-on-unreachable design), and an open PR #747 (`sync/docs-drift-2026-30`,
a genuine doc-drift-author fallback fixing a real gap: `tidb-admin-extras`
missing from `docs/dependency-tree.md`'s on-demand section). PR #747 was
created moments before this cycle started and is still in progress (not
stale) — left untouched per STEP 1b, no action needed from this session.

This session's own branch naming for this note deliberately avoids the
`cycleN` numbering the other session is also using, to prevent any future
branch-name collision between the two concurrently-running sessions.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record — not a stopping point. The run
continues to watch for a standing-issue confirmation or a genuinely new
signal in subsequent cycles per `executor.prompt.md` STEP 8.
