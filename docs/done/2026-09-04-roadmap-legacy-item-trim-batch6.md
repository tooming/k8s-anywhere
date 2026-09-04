# ROADMAP.md legacy `[x]` item trim — batch 6

Continuing the pilot batch, batch 2, batch 3, batch 4, and batch 5
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md)).

## What was done

Trimmed 3 more legacy items — a smaller batch than 3-5, since the
easy-to-verify candidates (a fully-inline spec with a real, findable
`docs/done/` mirror) are now scarcer — each verified against its real
`docs/done/` mirror before touching the ROADMAP text:

- `make capstone-demo` + `scripts/capstone-demo.sh` →
  [docs/done/2026-06-18-capstone-demo-target.md](2026-06-18-capstone-demo-target.md)
  (PR #225 — the mirror's own `**PR:** TBD` placeholder resolved via GitHub
  search, confirmed `merged: true`)
- cert-manager engine + self-signed root CA bootstrap →
  [docs/done/2026-07-16-cert-manager-engine.md](2026-07-16-cert-manager-engine.md)
  (PR #439 — this mirror already had a real link)
- `infra/live/README.md` + `docs/dependency-tree.md` — document the
  `oracle/` backend (RFC #377 item 5) →
  [docs/done/2026-07-13-oracle-backend-docs.md](2026-07-13-oracle-backend-docs.md)
  (PR #384 — this mirror already had a real link)

Two candidates found by this cycle's scan were deliberately **not**
trimmed:

- **"Flip `Application` `repoURL`s ... to the Forgejo remote"** (a live-
  cluster session record, PR #1205) — no `docs/done/` mirror exists for
  it at all (live-cluster interactive sessions don't always produce one),
  so there is nothing to point ROADMAP.md at without inventing a mirror
  file this cycle didn't actually verify end-to-end. Left as a candidate
  for a future cycle that's willing to author a proper `docs/done/`
  mirror first.
- **"Author retroactive ADR(s) for GitLab and the LGTMP observability-
  stack internals"** — this entry is itself a planner resolution note
  (already explains inline how RFC #1073 + PR #1076 closed it), not an
  executor build spec with one clean `docs/done/` mirror to point to.
  Trimming it would mean synthesizing a link across multiple PRs/ADRs
  rather than pointing at a single verified mirror — doesn't fit this
  cleanup's established pattern, left as-is.

Each trimmed item's full inline text replaced with the established
short-pointer format. No information lost — the full detail already
lived in the linked `docs/done/` files, confirmed equivalent by reading
all three before editing.

## Result

`ROADMAP.md`: 6944 → 6899 lines (45 lines saved from 3 items). ~154
legacy items remain for future bounded cycles to continue against — the
lens is thinning out (only 2 more candidates found this cycle, both
deliberately skipped above), so a future cycle should widen the search
(items with a `docs/done/` mention already present, in case any of those
still carry a lot of inline duplication alongside the pointer, or the
~150 truly untouched `[x]` items with no full-text scan performed yet by
this specific heuristic).

No `gitops/` change. `make ci` passes green.

## PR

(filled in after PR creation)
