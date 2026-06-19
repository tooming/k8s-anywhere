# docs/roadmap/incoming — architect item spool

New 🟡 roadmap items proposed by the architect routine land here as individual
files (`YYYY-MM-DD-arch-<slug>.md`), one file per run. The planner absorbs them
into `ROADMAP.md` and deletes them on its next run.

## Why this exists

Multiple nightly runs all commit to the same `main`-based branch and all
previously appended items to the same "Future 🟡" section of `ROADMAP.md`.
When the user merges those PRs in the morning the second (and third) PR has a
merge conflict on that section.

This directory avoids the conflict: each architect run writes a **unique
filename** (never conflicts with another run's file), and only the planner — a
single writer — ever modifies `ROADMAP.md`'s backlog sections.

## File format

Each file contains one or more standard ROADMAP list entries:

```markdown
- [ ] 🟡 **Short title** (CHARTER Objective OX, RFC #NNN — architect decision YYYY-MM-DD).
  <body text>
  (<branch-slug-hint>)
```

The planner places each entry in the correct ROADMAP section (Now/next,
Backlog, or Cross-cutting), de-duplicates against existing items, and deletes
this file from the branch once incorporated.
