# Remove the dead Harbor containerd registry-mirror block from `infra/modules/k3d-cluster/k3d-config.yaml.tftpl`

Found live 2026-09-08 (planner gap analysis, same "leftover config from a
removed component" class as this run's earlier ADR-0016/0017 fix, this time
in `infra/` rather than `docs/decisions/`): `find gitops -iname "*harbor*"`
and `grep -n "harbor-up\|harbor-down" Makefile` both return zero results
(Harbor is fully gone, not even an on-demand target), yet the k3d bootstrap
template's comment block still described it as "on-demand (ADR-0024) — this
mirror sits inert, harmlessly, whenever Harbor isn't running; it only
matters once `make harbor-up` is used" — a `make harbor-up` target that no
longer exists. `tests/k3d-registry-mirror.bats` (6 tests) existed solely to
assert this dead block's presence/shape, so it had to be deleted (not just
updated) alongside the template edit, or `make ci` would keep passing by
testing dead code.

Harbor was removed entirely 2026-09-07 (ADR-0024), no replacement, but this
bootstrap template still rendered a `registries: mirrors:
"harbor.127.0.0.1.nip.io": endpoint: http://harbor.harbor.svc.cluster.local`
block pointing at a Kubernetes Service that will never exist again.

## What was done

- Deleted the `registries:` block and its preceding explanatory comment
  (the `nip.io` cross-context DNS explanation, the Harbor Service redirect
  rationale) from `infra/modules/k3d-cluster/k3d-config.yaml.tftpl`. The
  `%{ if disable_traefik || disable_default_cni ~}` conditional block below
  it (Traefik/CNI disable flags, unrelated to Harbor) was left untouched.
- Deleted `tests/k3d-registry-mirror.bats` entirely (all 6 tests existed
  only to assert the now-removed block's presence/shape).
- Checked for dangling references to the deleted test file:
  `tests/drift-detectors.bats`, `tests/hook-scripts-coverage.bats`, and
  `tests/frozen-monolith-lib.bats` do not enumerate or reference
  `tests/k3d-registry-mirror.bats` by name — no frozen-file-list guard
  needed updating. `tests/k3s-version-pin.bats` (the other bats file that
  reads this same template) makes no assertion about the `registries:`
  block or Harbor — unaffected by this change.
- Confirmed the Oracle backend (`infra/modules/oracle-k3s-cluster/`) has no
  equivalent Harbor mirror config (`grep -rn "harbor"` returns zero hits) —
  this was a local-backend-only fix.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green), confirming the removed
test file's absence doesn't break `tests/hook-scripts-coverage.bats` or any
other frozen-file-list guard, and that the template still renders valid
k3d config for every `disable_traefik`/`disable_default_cni` combination.

## PR

[#1516](https://github.com/tooming/k8s-anywhere/pull/1516) (autonomous
scheduled executor run, cycle 4: item picked directly from the
freshly-refilled "Now / next" lane after cycle 3's `plan/*` PR #1515).
