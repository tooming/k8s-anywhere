# `make harbor-up` / `harbor-down` targets

Add `make harbor-up` (`$(call argocd-sync,harbor)` then `$(call argocd-sync,harbor-extras)`)
and `make harbor-down` (`$(call argocd-delete,harbor-extras)` then `$(call argocd-delete,harbor)`)
— mirroring the existing `artifactory-up`/`artifactory-down` targets. Makefile change
pre-approved by ADR-0024 per WAYS-OF-WORKING.md §2. Extend `tests/harbor.bats` with six
clusterless structural assertions: `.PHONY` targets present; `harbor-up` references both
`harbor` and `harbor-extras` via `argocd-sync`; `harbor-down` references both via
`argocd-delete` (extras deleted before harbor, matching the artifactory-down order).

## PR

#308
