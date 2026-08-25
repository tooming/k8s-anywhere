# chore: trim 5 more completed ROADMAP.md items' duplicated writeups (batch 3)

JANITOR-fallback cleanup, reached via `executor.prompt.md` STEP 6b — this
run's thirteenth cycle, continuing the incremental ROADMAP.md trim started in
batch 1 (PR #1320) and batch 2 (PR #1321). Same method, same safety argument
(every checked-off item's writeup is already mirrored into `docs/done/` at
completion time — trimming the ROADMAP.md copy to a pointer loses nothing).

## Method (unchanged from batches 1-2)

For each candidate item: confirmed a matching `docs/done/*.md` file exists
with a real, non-placeholder PR link; read the file and confirmed it covers
the same substance as the ROADMAP.md item; only then replaced the item body
with a title + link + PR number.

## This batch

Five more items, continuing sequentially from where batch 2 left off in the
"Now / next" section's completed-item history:

- `scripts/forgejo-runner-ensure.sh` bats coverage → [docs/done/2026-08-17-forgejo-runner-ensure-bats-coverage.md](../done/2026-08-17-forgejo-runner-ensure-bats-coverage.md) (PR #1201)
- `docker:29`/`docker:29-dind` CI-image exact-patch pin → [docs/done/2026-08-17-docker-ci-image-explicit-pin.md](../done/2026-08-17-docker-ci-image-explicit-pin.md) (PR #1199)
- GitLab CE `19.2.1-ce.0` → `19.2.2-ce.0` security bump → [docs/done/2026-08-17-gitlab-19-2-2-security-bump.md](../done/2026-08-17-gitlab-19-2-2-security-bump.md) (PR #1197)
- Valkey `8.0.10-alpine` → `8.1.9-alpine` security bump → [docs/done/2026-08-17-valkey-8-1-9-security-bump.md](../done/2026-08-17-valkey-8-1-9-security-bump.md) (PR #1195)
- Forgejo compose stack, additive alongside GitLab (item 1 of the 7-item
  GitLab → Forgejo migration list, ADR-0035) → [docs/done/2026-08-11-forgejo-compose-stack-roadmap-bookkeeping.md](../done/2026-08-11-forgejo-compose-stack-roadmap-bookkeeping.md)
  (PR #1105, bookkeeping PR #1106)

The last item is the first entry of a 7-item numbered migration list with
shared narrative framing across all entries; only the individual item's own
body was trimmed, not the list's shared intro sentence ("seven items...work
top-to-bottom, each its own PR" — still needed context for the remaining
un-trimmed entries in that same list).

ROADMAP.md: 6,763 → 6,524 lines this batch (running total from the original
7,167: 643 lines / ~46 KB across all three batches). ~165 completed items
remain — left for further bounded cycles.

`make ci`: green (full local run including real `bats`).

## PR

https://github.com/tooming/k8s-anywhere/pull/1322
