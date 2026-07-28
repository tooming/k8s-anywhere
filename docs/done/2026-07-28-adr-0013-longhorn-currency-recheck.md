# ADR-0013 periodic re-check: Longhorn `1.11.3` pin kept (flip condition not met)

CHARTER **Core Values** §"Docs & dashboards don't drift". Architect-role fallback
(`executor.prompt.md` STEP 6b), picking "ADRs due for re-evaluation" from rule #9's
coverage/hardening list — ADR-0013 had the oldest re-evaluation log entry
(2026-07-18) of any version-tracking ADR in the repo, ten days stale relative to
every other ADR's last check (all touched within the last 1-3 days). "Now / next"
remains fully gated on standing maintainer-confirmation issues #631/#632/#633
(re-checked this cycle — still no confirmation comments on any of the three).

## What was checked

Re-verified the 2026-07-18 flip condition (RFC #528: "re-check when the `1.11.x`
line itself approaches its own end-of-support window, or a specific CVE is filed
against the then-current pin") directly against live sources (ADR-0004):
`longhorn/charts`' real tags via `raw.githubusercontent.com` (since
`api.github.com` and `charts.longhorn.io` are both proxy-blocked from this
sandbox). Confirmed `longhorn-1.12.0` is still the only chart release past the
pinned `1.11.3` — no `1.11.4`, `1.12.1`, or later tag exists yet.

## Why this is "kept," not a bump

Neither flip condition has fired: `1.11.x` is only 10 days into its support
window (nowhere near end-of-life under the pre-1.8 12-month policy), and no CVE
has been filed against `1.11.3`. The 2026-07-18 decision to deliberately stay one
minor line behind `1.12.x` was itself reasoned and explicit — `1.12.0` shipped
the V2 Data Engine's GA, "a bigger behavioral surface change than [a] routine
currency bump warrants" — not an oversight to correct. Per CLAUDE.md, silently
overriding a binding, reasoned architect decision without its own stated flip
condition firing would itself be the violation; the correct action when a
periodic re-check finds the decision still holds is to record that explicitly,
not to bump anyway just because a newer version exists.

(Distinguishing note: this is the opposite conclusion from PR #808's
`docs/decisions/context.md` sweep — that fix corrected version *citations* that
had gone stale relative to an already-bumped live pin, an unintentional drift. This
is a live *pin* that a prior architect decision deliberately chose not to move
yet, with its own stated re-check trigger not yet satisfied.)

## What changed

- `docs/decisions/adr-0013-longhorn-block-storage.md`: new dated
  `### 2026-07-28` re-evaluation log entry recording the re-check, its evidence,
  and the "kept" decision. No code/manifest change — `gitops/platform/longhorn.yaml`'s
  `targetRevision: 1.11.3` is unchanged.

`make ci` passes locally (all real checks green; no drift-check regression since
nothing self-tracking changed). No `docs/dependency-tree.md` update needed (chart
version unchanged).

PR: (this run's `arch/adr-0013-longhorn-currency-recheck` branch)
