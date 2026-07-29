# Bump `actions/checkout` v7.0.0 → v7.0.1

CHARTER **Core Values** §"Clusterless gates stay green" / general CI dependency
hygiene. RFC #611 pinned `actions/checkout` to `v7.0.0` (2026-07-19); a same-major
patch release, `v7.0.1`, shipped upstream 2026-07-20 (one day later) — a fresh
same-day sweep of the four RFC #611-pinned actions found it.

- Component: `actions/checkout` (GitHub Actions marketplace)
- From → To: `v7.0.0` (`9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0`) →
  `v7.0.1` (`3d3c42e5aac5ba805825da76410c181273ba90b1`)
- Why this version: highest stable release, same major line, no pre-release, no
  version-pinning ADR (this repo has no ADR pinning GitHub Actions versions —
  RFC #611/`tests/github-actions-pins.bats` is the binding record instead). Verified
  directly against the real tag (`raw.githubusercontent.com/actions/checkout/v7.0.1/package.json`
  reports `"version": "7.0.1"`) and its commit SHA
  (`git ls-remote --tags https://github.com/actions/checkout.git`, a lightweight
  tag pointing straight at the commit — no `^{}` dereference needed).
- `actions/cache` (`v6.1.0`), `actions/github-script` (`v9.0.0`), and
  `hashicorp/setup-terraform` (`v4.0.1`) — the other three RFC #611 pins — were
  re-checked in the same sweep and are still each at their latest real release;
  no change needed.

Updated all 10 `uses: actions/checkout@...` occurrences across
`.github/workflows/{ci,auto-update-prs,oracle-cluster-apply,oracle-cluster-apply-retry,pr-up-to-date}.yml`.
Updated `tests/github-actions-pins.bats`'s exact-pin assertion (RFC #611's
pin-assertion pattern) and added a companion assertion that no workflow still
references the pre-bump `v7.0.0` SHA (mirrors the existing "no
pre-RFC-#611 Node-20-era pin" test's shape).

`make ci`-relevant checks: `bats tests/github-actions-pins.bats` (8/8 ok),
`scripts/lint.sh` (shellcheck+yamllint clean), `scripts/ci-parity-check.sh`
(green — this change touches no `make ci`/`ci.yml` script wiring at all, just a
`uses:` pin, so parity is unaffected).

## PR

[#640](https://github.com/tooming/k8s-anywhere/pull/640)
