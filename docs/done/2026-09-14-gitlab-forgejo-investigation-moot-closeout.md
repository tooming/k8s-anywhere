# Close out the stale gitlab→forgejo rename investigation file

## What

`docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md` ended at
its 2026-09-06 "still blocked, same reason as the original finding" update
— it was never updated to reflect that both GitLab and Forgejo were
removed from the lab entirely the very next day (2026-09-07), which made
the whole investigation (how to rename `gitlab-*.sh` scripts to a
`forgejo-*.sh` equivalent) moot. The corresponding `ROADMAP.md` item
(line ~1162) was already correctly closed `[x]` with a "closed as moot
2026-09-07" note — this investigation file, which the ROADMAP item links
to for full findings, was the one place still implicitly presenting this
as an open, unresolved question.

## Why it matters

A reader following the ROADMAP item's link to this file for "full
findings, recommendation, and update history" would land on a file that
never says the investigation's premise stopped applying — a real, if
minor, inconsistency between the two documents describing the same item.

## Verification

- `grep -n "gitlab-forgejo-rename" ROADMAP.md` — confirmed the ROADMAP
  item is already `[x]` closed with the moot note (2026-09-07).
- `ls scripts/gitlab-*.sh scripts/forgejo-*.sh` — confirmed directly, no
  such scripts exist in the repo today.
- `grep -n "gitlab-up\|gitlab-configure\|forgejo-up\|forgejo-configure" Makefile`
  — confirmed no such targets remain either.

## Fix

Added a closing "## Update 2026-09-07 — moot" section to the investigation
file, mirroring the ROADMAP item's own closing note and citing the direct
verification above. Nothing else in the file changed — the investigation's
original findings stay as accurate history.

## Verification (CI)

`make ci` — full clusterless suite (bats, kustomize, kubeconform,
terraform, ~40 drift-detector scripts) — green except the expected
`docs-done-pr-link-check` placeholder failures, resolved by the standard
follow-up commit backfilling this PR's real link.

## PR

https://github.com/tooming/k8s-anywhere/pull/1613
