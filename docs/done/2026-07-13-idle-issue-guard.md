# Idle-issue guard — stop declaring "no work" on the strength of one blocked item

**Bug:** a session (this one, issue #390) checked ROADMAP's *Now / next* lane, found
every unchecked 🟢 item gated on a live-cluster/maintainer confirmation, and reported
"no work to do" without running the other always-available, clusterless checks first:
`make ci` (doc/dashboard drift) and a CHARTER.md-Objectives-vs-ROADMAP.md-checked-items
diff (an un-groomed gap the planner should have filed). The user correctly flagged this
as premature — the repo's CHARTER goal (O4 signed-image enforcement, the Harbor
migration) genuinely isn't done yet, and "no actionable item in one narrow lane" is not
the same claim as "no work exists."

**Fix (this run):** re-ran the full fallback chain by hand — `make ci` (green, no doc
drift), a CHARTER Objectives (O1–O6) vs ROADMAP checked-items diff (no ungroomed gap;
the one 🟡 item, the vault PSA-restricted audit, already has a documented "no RFC
needed yet" resolution) — confirmed the prior idle report (#390) was accurate in
substance, but wrong in process: it never showed that work.

**Mechanical guard (prevents recurrence):**
- ROADMAP.md rule #9 rewritten: idle may only be declared after `make ci` is confirmed
  green, a CHARTER-vs-ROADMAP diff is done, unRFC'd 🟡 items are checked for
  architect-tier RFC-writability, and open issues are triaged — *and the idle issue body
  must document the `make ci` and CHARTER-diff results*, not just list blocked items.
- `scripts/idle-issue-guard-check.sh` — structural check (bats-tested directly via env
  vars, no fixture needed) that an idle/no-work-titled issue or comment's body mentions
  both `make ci` and `CHARTER`; fails otherwise.
- `scripts/idle-issue-guard-hook.sh` — `PostToolUse` hook wired in `.claude/settings.json`
  on `mcp__github__issue_write|mcp__github__add_issue_comment`, nudging (non-blocking,
  matching the existing hook philosophy) whenever an idle-flavored issue/comment is
  posted without that evidence.
- `tests/drift-detectors.bats` — four new cases covering pass/fail/partial-evidence for
  `idle-issue-guard-check.sh`.

## PR

https://github.com/tooming/k8s-anywhere/pull/391
