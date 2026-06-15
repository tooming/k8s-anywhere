# docs/backlog/ — per-run backlog grooming notes

One Markdown file per architect/planner run that records that run's 🟡 backlog
narrative — the "what was filed / groomed / unblocked this run" commentary that
used to accrete in the `ROADMAP.md` `## Backlog` footer paragraph. Created by the
architect or planner routine in the same PR that does the grooming — never by
humans directly.

## Filename convention

```
YYYY-MM-DD-<branch-slug>.md
```

## Why a directory instead of a ROADMAP.md footer paragraph

Previously every architect/planner run appended its grooming commentary to the
same `_Future 🟡 entries…_` paragraph at the end of `ROADMAP.md` `## Backlog`.
With multiple PRs open concurrently, every PR touched the same lines → git
conflicts on every rebase (e.g. PR #207 vs PR #204, June 2026).

Using one file per run means each PR creates a new, unique file → no two PRs ever
touch the same path → zero structural conflicts. This mirrors the
[`docs/done/`](../done/README.md) pattern adopted for the `## Done` section
(commit `aad0e49`).

The discrete 🟡 backlog **items** themselves stay in `ROADMAP.md` `## Backlog`
(they are the live work queue, tagged 🟢/🟡/🔴); only the per-run *narrative
commentary* moves here.

## File format

```markdown
# <Run title — e.g. architect run 2026-06-14>

<The grooming narrative: which 🟡 items got RFCs, which were groomed into 🟢,
which ADRs landed, what the next run should pick up.>

## PR

PR #NNN — https://github.com/tooming/k8s-lab/pull/NNN
```
