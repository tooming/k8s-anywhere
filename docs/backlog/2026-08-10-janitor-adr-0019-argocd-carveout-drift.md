# Janitor note — 2026-08-10 (ADR-0019 documented a removed Kyverno carve-out)

**Reached via:** `executor.prompt.md` STEP 6b, JANITOR fallback, tenth cycle this run
(after two consecutive `[Action needed]` cycles — #1089, #1090 — found nothing
actionable via shallow/mechanical sweeps). Delegated a deeper, judgment-based
gap-analysis sweep to a subagent this cycle rather than repeating the same shallow
grep-based checks a third time, per STEP 8's "widen the lens" guidance.

**What was found:** `docs/decisions/adr-0019-kyverno-admission-engine.md` still
documented a Kyverno `disallow-latest-tag` carve-out for the `argocd` namespace as
active/pending, in two places (its policy table and its "Carve-outs" bullet list).
In reality, that carve-out's own flip condition was met and the exclusion was
**removed 2026-08-06** (issue #999, PR #1037, a live-cluster session's own commit
`f7b415e`) — `gitops/kyverno/policies/disallow-latest-tag.yaml`'s `exclude` list is
`[capstone, inkless]` only, the file's own header comment documents the removal in
detail, and `tests/kyverno.bats` carries a regression test
(`"disallow-latest-tag no longer excludes the argocd namespace (issue #999
resolved)"`) asserting `argocd` stays absent. The ADR was never touched by that
commit — a real, verified drift between the binding decision record (ADR-0019) and
the actual enforced policy + its own recurrence guard.

This is exactly the class of bug ADR-0004 exists to prevent: a "decisions written
down" document that no longer matches the real, live-verified state of the thing it
supposedly decided. Fixed by:
1. Shortening the policy-table cell to note only the `capstone`/`inkless`
   carve-outs remain, with a one-line pointer to the Re-evaluation log for the
   `argocd` removal's full history.
2. Editing the "Carve-outs in the initial policy set" bullet list the same way.
3. Adding a new dated Re-evaluation log entry (2026-08-06) recording the full
   removal history — trigger, decision, live verification, and an explicit note
   that no further flip condition is pending (the carve-out is fully closed, not
   held open).

**No new mechanical guard added** — `tests/kyverno.bats` already carries the live
regression test against the actual policy YAML (added in PR #1037); the gap was
purely in the ADR's own prose, which has no existing drift-detection mechanism
(unlike `context.md`'s version citations, which `context-doc-version-sync-check.sh`
already enforces mechanically). A prose-vs-manifest consistency checker for every
ADR carve-out claim would be a disproportionate new gate for what appears to be an
isolated instance — grepped for other ADRs citing carve-outs tied to now-closed
issues and found no other similarly stale claim.

**Why this cycle used a subagent rather than direct grep:** two prior cycles this
run (8 and 9) already exhausted every shallow/mechanical angle (currency sweeps,
TODO/FIXME scan, doc-drift checks, GitHub Actions pin currency, namespace-coverage
recount). Finding this required cross-checking an ADR's prose against the actual
live policy YAML and a bats test — judgment-based reading, not pattern-matching —
so this cycle delegated exactly that kind of check instead of repeating a third
shallow pass that would likely have come up empty again.
