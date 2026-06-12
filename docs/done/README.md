# docs/done/ — completed delivery records

One Markdown file per completed ROADMAP item. Created by the executor routine in the same PR that delivers the work — never by humans directly.

## Filename convention

```
YYYY-MM-DD-<branch-slug>.md    # new entries (post-migration)
<slug>.md                      # legacy entries migrated from ROADMAP.md ## Done
```

## Why a directory instead of ROADMAP.md ## Done

Previously the executor prepended every done entry to the same `## Done` section in ROADMAP.md. With multiple PRs open concurrently, every PR touched the same lines → git conflicts on every rebase.

Using one file per delivery means each PR creates a new, unique file → no two PRs ever touch the same path → zero structural conflicts.

## File format

```markdown
# <Title of the ROADMAP item>

<Full description text from the ROADMAP item>

## PR

PR #NNN — https://github.com/tooming/k8s-lab/pull/NNN
```
