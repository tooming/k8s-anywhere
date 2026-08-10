# Janitor note — 2026-08-10 (ADR-0021's "Files this work will touch" table understated the Schedule count)

**Reached via:** `executor.prompt.md` STEP 6b, JANITOR fallback, twelfth cycle this
run. Third consecutive subagent-delegated deep gap-analysis sweep (following
cycles 10 and 11's real ADR-0019/ADR-0016 findings), scoped to CHARTER Objective
measurement mechanisms, `docs/dependency-tree.md` sync-wave tables, and other ADRs'
"Files this work will touch"/carve-out tables.

**What was found:** `docs/decisions/adr-0021-velero-backup-restore.md`'s "Files this
work will touch" table (added when the ADR was first written, describing the
original pilot scope) still said `gitops/velero/schedules/*.yaml` holds "Four
`Schedule` CRs" and `tests/velero.bats` covers "four schedules." In reality there
are **six**: `capstone-daily`, `data-daily`, `inkless-daily`, `observability-daily`,
`tidb-daily`, `vault-daily` — verified directly (`ls gitops/velero/schedules/`,
six files; `tests/velero.bats` has six matching `@test` blocks, lines 281–334, not
four). The ADR's own "Schedule set" table (§Decision) and its Re-evaluation log
already correctly document the 2026-07-29 growth from four to six (a gap audit
found `observability` and `inkless` both held real PVCs with no backup Schedule,
closing a mismatch with CHARTER O3's "every stateful namespace" claim) — only the
"Files this work will touch" summary table at the bottom was never updated in that
same pass.

This is the same drift shape as the ADR-0019/ADR-0016 fixes earlier today, but
smaller in scope — a stale count in a summary table, not a claim about a
specific pod/manifest that no longer exists. Fixed by updating both cells to say
"Six" and cross-reference the already-correct "Schedule set" table + Re-evaluation
log entry, rather than duplicating the full explanation a third time in the file.

**No new mechanical guard added** — same reasoning as the two prior fixes: a
one-off prose staleness in a summary table that has no existing drift-detection
mechanism. `tests/velero.bats` itself is the real, live-enforced source of truth
for the schedule count (six `@test` blocks); nothing about this ADR's own summary
table being briefly stale ever risked a real config drift, only a documentation
accuracy gap.

**Sweep scope this cycle (for the record):** CHARTER Objectives O1/O3/O4/O6
measurement mechanisms — all verified to genuinely measure what they claim (O4's
named CI gate doesn't exist yet, but that's already an open, correctly-tracked
ROADMAP item, not a false claim about current state); every `docs/dependency-tree.md`
sync-wave table row spot-checked against real `argocd.argoproj.io/sync-wave`
annotations — all matched; ADR-0012 (Istio/Kiali), ADR-0023 (Kargo), ADR-0024
(Harbor) "Files"/carve-out tables — all verified accurate. Only the ADR-0021 finding
above was real.
