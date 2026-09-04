# docs/done/ PR-link integrity fix — 80 files backfilled + mechanical guard hardened

**CHARTER "Everything as code; GitOps deploys it" + the repo's own docs/done/
convention** (JANITOR-fallback finding surfaced while running the ongoing
ROADMAP.md legacy-item-trim lens — verifying each trimmed item's `docs/done/`
mirror against a real PR link, per
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
turned up a much larger integrity gap than any single item).

## What was wrong

`scripts/docs-done-pr-link-check.sh` (the drift guard added 2026-07-28 after a
38-file backfill) only matched an **allowlist of specific known placeholder
wordings** — an HTML comment, a bare parenthetical, or a parenthetical citing
a branch name. That narrow match let dozens of *other* unresolved shapes slip
through silently for months: a bare branch name with no PR reference at all
(`auto/cosign-make-up-wiring`), prose like "this session's branch" or
"(autonomous scheduled run — executor routine)" never naming the PR, other
differently-worded unresolved placeholders (`PR to be filled in.`,
`#auto/cilium-agent-metrics`), and literal un-substituted templates
(`PR #NNN — .../pull/NNN`, `.../pull/TBD`) where the routine's own template
text was never filled in before the file was committed.

## What was fixed

**80 `docs/done/*.md` files** had their `## PR` section content replaced with
the real PR URL. Every replacement was found the same way and independently
verified, never guessed:

1. `git log --all --oneline --diff-filter=A -- docs/done/<file>` to find the
   commit that added the file.
2. Extract the **last** `#[0-9]+` token in that commit's squash-merge subject
   line (GitHub always appends the real PR number there — the *first* match
   in a subject can be an unrelated RFC/issue reference quoted earlier in the
   same line; an earlier pass in this cycle caught itself making exactly that
   mistake by having a bogus PR number 404 against the GitHub API).
3. Confirm via the GitHub API (spot-checks across the batch, both files found
   outside the original grep sweep) that the resulting PR is real and its
   title matches the doc's own subject matter.

Full list of the 80 files and their resolved PR numbers is in this branch's
diff (`docs/done/*.md`, one line each under `## PR`) — not reproduced here to
keep this entry short; every one resolves to a real
`https://github.com/tooming/k8s-anywhere/pull/NNN` URL.

## Mechanical guard (prevent recurrence)

Per CLAUDE.md's "every bugfix must prevent recurrence" rule, an allowlist of
placeholder wordings can never be complete — the fix instead flips the
check's *logic*: `scripts/docs-done-pr-link-check.sh` now runs a **second,
broader pass** after the original placeholder-wording check. For every
`docs/done/*.md` file that has a `## PR` heading (files without one predate
the convention entirely — out of scope, per `docs/done/README.md`'s own
filename-convention note), the section's content **must** contain either a
real `github.com/.../pull/NNN` URL or a bare `#NNN` reference; anything else
fails the check, regardless of exact wording. `docs/done/README.md` itself is
excluded — its `## PR` section is the convention's own literal example text,
not a delivery record.

`tests/docs-done-pr-link-check.bats` gained three new cases exercising this
second pass directly, plus three new fixtures under
`tests/fixtures/docs-done-pr-link-check/`:

- `drift-bare-branch-name/` — a `## PR` section naming only a branch, no PR
  reference at all → must fail with the new message.
- `no-pr-heading/` — a legacy file with no `## PR` heading → must be skipped
  (not flagged).
- `readme-excluded/` — a `docs/done/README.md` carrying the convention's own
  literal `PR #NNN` example text → must be skipped (not flagged).

All 9 bats cases in that file pass; `make ci` passes green (bats, shellcheck,
yamllint, kustomize, terraform, drift checks all clean) with all 80 fixed
files and the new check logic together.

No `gitops/` change — this cycle is docs + tooling only.

## PR

https://github.com/tooming/k8s-anywhere/pull/1411
