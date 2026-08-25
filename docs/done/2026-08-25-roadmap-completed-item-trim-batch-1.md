# chore: trim 5 completed ROADMAP.md items' duplicated writeups (batch 1)

JANITOR-fallback cleanup, reached via `executor.prompt.md` STEP 6b — this
run's eleventh cycle, and the promised follow-up to the earlier
`docs/roadmap/investigations/` extraction (PR #1310): trimming the
~180 already-**completed** `[x]` items' inline writeups, explicitly scoped
out of that earlier PR as "a much larger, higher-risk cleanup... left for a
future bounded cycle." This is that cycle's first bounded installment.

## Why this is safe

Every checked-off (`[x]`) ROADMAP.md item's writeup is, by this repo's own
rule #7, mirrored into a `docs/done/YYYY-MM-DD-<slug>.md` file at the time
the item completes — the permanent record. Once that mirror exists (with a
real, non-placeholder PR link — `scripts/docs-done-pr-link-check.sh`
already enforces this in `make ci`), the ROADMAP.md copy is pure
duplication: every fact, citation, and caveat in it is already preserved
verbatim (allowing for tense — "Bump" instructional → "Bumped" retrospective
— not substance) in the matching `docs/done/` file. Trimming it to a
pointer loses nothing a reader can't get from that file.

## Method

For each candidate item: (1) confirmed a matching `docs/done/*.md` file
exists with a real (non-placeholder) PR link — checked directly, not
assumed; (2) read the full `docs/done/` file and confirmed it covers the
same verification findings, changes, and caveats as the ROADMAP.md item
(substance match, not byte-identical — the `docs/done/` version is written
retrospectively); (3) only then replaced the ROADMAP.md item body with a
title + a link to the `docs/done/` file + the PR number.

## This batch

Five items, all from the "Now / next" section's already-completed currency-
bump history (chosen because their `docs/done/` mirrors were the ones this
run's own earlier cycles had already re-read and cross-checked, so their
accuracy was already confirmed, not just assumed for this cleanup):

- Vault Helm chart `0.34.0` → `0.34.1` → [docs/done/2026-08-19-vault-chart-0-34-0-to-0-34-1.md](../done/2026-08-19-vault-chart-0-34-0-to-0-34-1.md) (PR #1269)
- Oracle-workflow Terragrunt `v1.1.1` → `v1.1.3` → [docs/done/2026-08-19-terragrunt-1-1-1-to-1-1-3.md](../done/2026-08-19-terragrunt-1-1-1-to-1-1-3.md) (PR #1273)
- CI Terraform `1.15.8` → `1.15.9` (CVE-2026-14978) → [docs/done/2026-08-19-ci-terraform-1-15-8-to-1-15-9.md](../done/2026-08-19-ci-terraform-1-15-8-to-1-15-9.md) (PR #1272)
- Grafana image `13.0.6` → `13.0.7` (CVE-2026-17183) → [docs/done/2026-08-19-grafana-image-13-0-6-to-13-0-7.md](../done/2026-08-19-grafana-image-13-0-6-to-13-0-7.md) (PR #1271)
- Cilium chart `1.18.12` → `1.18.13` → [docs/done/2026-08-19-auto-cilium-1-18-12-to-1-18-13.md](../done/2026-08-19-auto-cilium-1-18-12-to-1-18-13.md) (PR #1252)

ROADMAP.md: 7,167 → 6,973 lines (194 lines / ~14 KB this batch). The
remaining ~175 completed items are a much larger undertaking (each needs
the same individual verification before trimming) — left for further
bounded cycles, not attempted in one shot here, matching the same
size-discipline reasoning PR #1310 already established.

`make ci`: green (full local run including real `bats`, 2874 tests — the
markdown-link-check confirms every new relative link resolves, and the
docs-done-pr-link-check confirms all five cited PR links are real).

## PR

https://github.com/tooming/k8s-anywhere/pull/1320
