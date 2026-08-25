# chore: trim 5 more completed ROADMAP.md items' duplicated writeups (batch 2)

JANITOR-fallback cleanup, reached via `executor.prompt.md` STEP 6b — this
run's twelfth cycle, continuing the incremental ROADMAP.md trim started in
batch 1 (PR #1320). Same method, same safety argument (every checked-off
item's writeup is already mirrored into `docs/done/` at completion time —
trimming the ROADMAP.md copy to a pointer loses nothing).

## Method (unchanged from batch 1)

For each candidate item: confirmed a matching `docs/done/*.md` file exists
with a real, non-placeholder PR link; read the file and confirmed it
covers the same substance as the ROADMAP.md item; only then replaced the
item body with a title + link + PR number.

## This batch

Five more items, continuing sequentially from where batch 1 left off in
the "Now / next" section's completed-item history:

- Aiven Inkless broker pin + Kyverno carve-out removal → [docs/done/2026-08-18-inkless-latest-tag-pin-kyverno-exclusion-removal.md](../done/2026-08-18-inkless-latest-tag-pin-kyverno-exclusion-removal.md) (PR #1217)
- kube-state-metrics chart `8.3.0` → `8.3.1` → [docs/done/2026-08-17-ksm-chart-8-3-1.md](../done/2026-08-17-ksm-chart-8-3-1.md) (PR #1204)
- `git-fixture-isolation-check.sh` false-positive bugfix → [docs/done/2026-08-17-git-fixture-isolation-check-false-positive-fix.md](../done/2026-08-17-git-fixture-isolation-check-false-positive-fix.md) (PR #1211)
- `dependency-register.md` GitLab → Forgejo row → [docs/done/2026-08-17-dependency-register-gitlab-to-forgejo.md](../done/2026-08-17-dependency-register-gitlab-to-forgejo.md) (PR #1209)
- ACK S3 chart `1.9.0` → `1.10.0` → [docs/done/2026-08-17-ack-s3-chart-1-10-0.md](../done/2026-08-17-ack-s3-chart-1-10-0.md) (PR #1203)

ROADMAP.md: 6,973 → 6,763 lines this batch (running total from the original
7,167: 404 lines / ~28 KB across both batches). ~170 completed items
remain — left for further bounded cycles.

`make ci`: green (full local run including real `bats`, 2874 tests).

## PR

https://github.com/tooming/k8s-anywhere/pull/1321
