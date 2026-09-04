# ROADMAP.md legacy `[x]` item trim — batch 3

Continuing the pilot batch and batch 2
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md)).

## What was done

Trimmed 5 more legacy items — the O1/O3 Velero + Argo Rollouts rollout
sequence — each verified against its real `docs/done/` mirror before
touching the ROADMAP text:

- Velero controller + Garage S3 backend →
  [docs/done/2026-06-12-velero-controller.md](2026-06-12-velero-controller.md)
  (PR #189)
- Velero Schedules — four stateful namespaces →
  [docs/done/2026-06-13-velero-schedules.md](2026-06-13-velero-schedules.md)
  (PR #198)
- `make dr-restore` + `scripts/dr-restore.sh` — Objective O3 enabler →
  [docs/done/2026-06-13-dr-restore-script.md](2026-06-13-dr-restore-script.md)
  (PR #199)
- Argo Rollouts controller →
  [docs/done/2026-06-13-argo-rollouts-controller.md](2026-06-13-argo-rollouts-controller.md)
  (PR #190)
- Capstone Rollout overlay + success-rate AnalysisTemplate →
  [docs/done/2026-06-13-capstone-rollout.md](2026-06-13-capstone-rollout.md)
  (PR #200)

Unlike the pilot/batch-2 items, these five `docs/done/` mirrors already
existed but each carried an unresolved `**PR:** (see GitHub)` /
`(autonomous scheduled run — executor routine)` placeholder instead of a
real link. Resolved every one first — found the actual merged PR via a
GitHub PR search per item (confirming `merged: true`, since two of the
five components each had an earlier same-named PR that was closed
*unmerged* and superseded by a second attempt — #179→#189 and #180→#190
— so the search match had to be verified against real merge state, not
just title text) — before pointing ROADMAP.md at them, rather than
propagating an unverifiable placeholder into the trimmed form (ADR-0004).
`make ci`'s existing `docs/done/ file has a real PR link` check stayed
green throughout (it was already passing before this cycle only because
that check accepts `(see GitHub)`-style prose as non-empty; it does not
itself verify the link resolves to a real, merged PR — this cycle did
that verification manually).

Each item's full inline text replaced with the established short-pointer
format. No information lost — the full detail already lived in the linked
`docs/done/` files (now with a real PR link too), confirmed equivalent by
reading all five before editing.

## Result

`ROADMAP.md`: 7297 → 7141 lines (156 lines saved from 5 items — the
largest single batch so far, since these five items' original inline specs
were unusually long). ~167 legacy items remain for future bounded cycles
to continue against.

No `gitops/` change. `make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1412
