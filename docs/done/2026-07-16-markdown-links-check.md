# New drift gate — markdown-links-check (broken internal doc links)

**Coverage/hardening fallback run**, continuing this session's lane (PRs #431, #434,
#435 closed the `scripts/*.sh` CI-pattern coverage gap; #433 fixed CHARTER/README
drift). ROADMAP.md's `Now / next` lane is fully gated this run. Rather than another
missing-bats-file pickup (that class is now fully closed — every `scripts/*.sh` has at
least one bats reference), this run adds a genuinely new mechanical guard the repo
didn't have at all.

## Gap found

Nothing checked that a relative markdown link (link text, then a parenthesized target
path) inside a tracked `*.md` file actually resolves to a real file. Docs get renamed and moved constantly in this repo
(`docs/done/`, `docs/backlog/`, ADRs, `docs/roadmap/incoming/`) — a rename that leaves a
stale cross-reference behind had no mechanical guard at all: not a `make ci` step, not
a PostToolUse hook, nothing. A one-off `grep`/`python3` sweep this run found the current
tree clean (0 broken links across 238 tracked markdown files), but "clean today" isn't
"stays clean" — CLAUDE.md's bugfix-prevents-recurrence principle applies equally to a
newly-found gap-class, not just a fix: the mechanical guard is the deliverable, not the
one-off finding.

## What shipped

- **`scripts/markdown-links-check.sh`** — walks every tracked `*.md` file (excluding
  `tests/fixtures/`, whose synthetic content is allowed to have intentionally-broken
  links for the drift-case fixture below), extracts markdown link targets via
  `grep -oP`, skips `http(s)://`/`mailto:`/pure-anchor links (external reachability is
  a different, network-dependent problem — out of scope), resolves the rest relative to
  the containing file's directory via `realpath -m --relative-to`, and fails if any
  target doesn't exist. `MDLINKS_ROOT` env-var override for fixture-tree testing,
  matching the existing `READMECHECK_ROOT`/`ROADMAPCHECK_ROOT`/`CHARTPINCHECK_ROOT`
  convention.
- **`make markdown-links-check`** target; wired into `make ci` (Makefile) and the
  GitHub Actions `drift` job (`.github/workflows/ci.yml`), immediately after
  `roadmap-check` in both, per CLAUDE.md's "kept in parity" rule.
- **`scripts/markdown-links-sync-hook.sh`** — PostToolUse companion, fires on any
  `*.md` edit, wired into `.claude/settings.json`'s `Edit|Write|MultiEdit` matcher
  block. Caught its own bug live during development: writing this PR's own
  `in-sync`/`drift` bats fixtures tripped the hook immediately (correctly — the
  fixture files really did reference not-yet-created paths at that point in the edit
  sequence), which is exactly the intended UX.
- **A real bug found and fixed while building the fixtures**: a relative `MDLINKS_ROOT`
  broke `realpath --relative-to` after the script's own `cd "$ROOT"` (the literal
  relative string stopped resolving from the new cwd). Fixed by resolving `ROOT` to an
  absolute path immediately after reading the env var, before the `cd`. Caught by
  actually running the fixture-pointed invocation locally, not just trusting the logic
  on paper — the `in-sync` fixture was reporting false failures until this fix.
  Documented as a comment in the script so the next `ROOT`-override script doesn't
  repeat it.
- **A second real false positive, found writing this very entry**: this document's own
  prose, describing the link syntax as a literal backtick-quoted example, was itself
  flagged as a broken link by the checker (and by its own PostToolUse hook, live, mid-edit)
  — a raw text match can't distinguish a real link from a doc *talking about* link
  syntax. Fixed at the tool level, not by permanently avoiding the example in prose:
  the check now strips fenced code blocks (`` ```...``` ``) and inline code spans
  (single backticks) before matching, so documenting markdown syntax — a near-certainty
  in a docs-heavy repo like this one — won't trip it again. Verified against both the
  inline-code and fenced-code cases with an ad hoc fixture before relying on it.
- New `tests/fixtures/markdown-links-check/{in-sync,drift}/` fixture trees and four new
  `tests/drift-detectors.bats` cases (in-sync passes, drift fails with the broken path
  named, external/anchor links ignored, real repo passes) plus three new
  `tests/hook-scripts-coverage.bats` cases for the sync-hook (empty payload, filtered
  non-`.md` file, real currently-clean `.md` file — matching the existing
  hook-coverage convention of positive-path-only coverage for hooks with no
  ROOT-override seam).

## Verification

`make ci` passes (full toolchain installed this session — see PR #431's `docs/done/`
entry). `shellcheck -S warning` clean on both new scripts.

## PR

https://github.com/tooming/k8s-anywhere/pull/436
