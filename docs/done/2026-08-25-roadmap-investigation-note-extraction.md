# chore: extract blocked-item investigation notes out of ROADMAP.md

JANITOR-fallback cleanup, reached via `executor.prompt.md` STEP 6b after this
run's own "Now / next" lane was found fully gated (all three unchecked items
re-checked: the two GitLab→Forgejo migration items and the legacy capstone
`Deployment` removal, still gated on issue #633 — re-checked live, no new
comment since 2026-08-17) and the PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER fallback passes all found nothing: no ungroomed
issues, no un-RFC'd 🟡 items, no `docs/roadmap/incoming/` file to absorb, no
currency/CVE gap on a spot-check of recently-touched components, `make ci`'s
own drift checks (readme/lab-ui/dependency-register) fully clean, and both
open issues (#633, #1229) already fully triaged.

## The footgun

ROADMAP.md had grown past 500 KB / 7,180 lines — large enough that this
session's own file-reading tool refused to load it in one call (a 256 KB
per-read cap). A big share of that growth has nothing to do with the file's
actual job (tracking the current backlog): every time an executor cycle
picked up a still-gated item and investigated it without completing it, the
full multi-paragraph writeup got appended directly into the item's ROADMAP.md
text, and none of it was ever pruned. Unlike a *completed* item — whose
writeup is already mirrored verbatim into a `docs/done/*.md` file, so
trimming the ROADMAP.md copy loses nothing — a *blocked* item's investigation
prose has no such mirror anywhere else. It just accretes, forever, across
however many cycles re-investigate the same still-gated item.

## The fix

Same pattern this repo already applies elsewhere (`## Done` → `docs/done/`,
per-run planner narrative → `docs/backlog/`, an oversized bats file →
`tests/<scope>-<name>.bats`): move the full writeup to its own file, keep
only a short pointer inline.

- Added `docs/roadmap/investigations/` (with a `README.md` explaining the
  convention) — one file per investigation, mirroring `docs/done/`'s
  per-item-file shape.
- Applied it to the one item that had already grown a large inline
  investigation block: the "Rename `scripts/gitlab-*.sh` →
  `scripts/forgejo-*.sh`" item. Its ~54-line "Investigated 2026-08-17..."
  writeup moved to
  `docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md`
  verbatim (nothing rewritten, nothing lost); the ROADMAP.md item now carries
  a 7-line summary + a link.
- Documented the convention in ROADMAP.md's own "Now / next" header block
  (next to the existing size-discipline / conflict-free-editing rules), so
  future investigations follow it instead of re-inlining.

**Explicitly out of scope for this cleanup:** the ~180 already-**completed**
`[x]` items still carry their full writeup inline too (duplicating their
`docs/done/*.md` mirror). Trimming those is a much larger, higher-risk
change — each of ~180 items needs its `docs/done/` mirror individually
verified before its ROADMAP.md copy can be safely replaced with a pointer,
and the resulting diff would be many multiples of WAYS-OF-WORKING.md §3's
~400-line-per-PR guidance. Left for a future bounded cycle (or several) to
pick up incrementally, not attempted here — this cycle only stops the
*unbounded* half of the growth (investigations with no mirror anywhere else),
which was also the more clear-cut, lower-risk half to fix.

`make ci`: green (only the link-check needed a new file to resolve against —
no gate touched or weakened).

## PR

https://github.com/tooming/k8s-anywhere/pull/1310
