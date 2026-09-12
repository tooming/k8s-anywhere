# Fix stale Q10 test-inventory answer in docs/dora-audit-readiness.md

Found live 2026-09-12 (JANITOR-fallback cleanup, executor.prompt.md STEP 6b,
reached after the "Now / next" lane was re-confirmed fully exhausted this
cycle — zero unchecked ROADMAP items, zero open issues — and
PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER all came up empty
again). While re-reading `docs/dora-audit-readiness.md`'s Q10 ("What test
types are performed, and against what?") to check for other real, buildable
gaps after Q12's fault-injection drills all landed this same run, found Q10
itself was stale: it was last written the day of the 2026-09-07
simplification and said only two real tests remain (`dr-test`, `dr-verify`)
— it was never updated after this run's own four `dr-chaos-*` drills
(`dr-chaos-argocd`, 2026-09-11; `dr-chaos-cert-manager`, `dr-chaos-traefik`,
`dr-chaos-lab-demo`, all 2026-09-12) landed, so it undercounted the lab's
actual test inventory by four real scripts.

**Fix:** updated Q10's **Answer**/**Evidence**/**Gap** fields to list all
four `dr-chaos-*` drills alongside `dr-test`/`dr-verify`, and revised the
**Gap** field's framing: fault-injection coverage is narrower in *kind* than
the old capstone-targeted drills (single-pod-kill only, no
network-partition equivalent) but broader in *coverage* (every always-on
component now has one, not just a single demo app) — stated plainly rather
than repeating the stale "two real tests remain" undercount. Backup/restore,
blue-green cutover, and continuous vulnerability scanning remain correctly
described as having no replacement (deliberate scope, per CHARTER.md's
"2026-09-07 simplification" — not restated here as a new finding).

`make ci` passes (doc-only change, all bats/lint/validate/drift checks
green). Behavior-preserving: no script, test, or gate changed — only a
stale prose description was corrected to match reality already established
by this run's own earlier PRs (#1573, #1576, #1577, #1578).

## PR

https://github.com/tooming/k8s-anywhere/pull/1579
