# docs/roadmap/investigations — per-item investigation notes

When an executor cycle picks up a ROADMAP item, investigates it, and finds it
is **not safely buildable this run** (needs live-cluster verification, a
design decision, or more research), the findings get written up in full
**here**, one file per investigation (`YYYY-MM-DD-<slug>.md`) — not inline in
the ROADMAP.md item body.

## Why this exists

An item that gets investigated but stays unchecked can be picked up and
re-investigated across many cycles/runs before it's finally unblocked. Each
pass historically appended its own multi-paragraph "Investigated on DATE ..."
writeup directly into the ROADMAP.md item text, and none of it was ever
pruned — because the item never reaches `docs/done/` (which only exists for
*completed* items). Unlike a completed item's writeup, which is mirrored
verbatim into a matching `docs/done/*.md` file (so trimming the ROADMAP.md
copy loses nothing), a **blocked** item's investigation prose had no such
mirror anywhere else — pure, permanent, un-recoverable-elsewhere bloat. This
is a real contributor to ROADMAP.md's growth past what standard tooling can
read in a single pass (a Claude Code session's Read tool has a 256 KB
per-call cap; ROADMAP.md exceeded 500 KB — first hit live, 2026-08-25).

Same fix pattern this repo already applies elsewhere (`## Done` →
`docs/done/`, per-run planner narrative → `docs/backlog/`, an oversized bats
file → `tests/<scope>-<name>.bats`): keep the compact, load-bearing summary
inline where the executor's STEP 3 needs it (title, readiness tag, one-line
"why still blocked" reason, a link here), move the full research writeup to
its own file.

## File format

Each file is the full investigation text that would otherwise have been
appended inline — background, what was checked, what was found, and the
recommendation. The ROADMAP.md item keeps only:

```markdown
**Investigated YYYY-MM-DD (<context>) — <one-line reason still blocked>.**
Full findings: [docs/roadmap/investigations/YYYY-MM-DD-<slug>.md](docs/roadmap/investigations/YYYY-MM-DD-<slug>.md).
```

Nothing is deleted — it just moves from directly inside ROADMAP.md's Backlog
section to its own file, exactly like a completed item's writeup already
lives in `docs/done/` instead of inline.
