# Fix stale "Keeping this in sync" claims in the three dependency docs

`docs/dependency-register.md`, `docs/dependency-concentration.md`, and
`docs/dependency-exit-runbooks.md` each carried a "Keeping this in sync" section
claiming no mechanical drift guard existed between these files — text that was true
when originally written but went stale the moment `scripts/dependency-register-check.sh`
(2026-08-24), `scripts/dependency-concentration-sync-check.sh` (2026-09-02/03), and
`scripts/dependency-exit-runbooks-sync-check.sh` (2026-09-02/03) actually landed and
were wired into `make ci`'s `drift` job. Left as-is, these sections were an ADR-0004
concern: three docs (whose entire purpose is to be an accurate rollup for DORA audit
readiness Q14/Q16/Q17) actively asserting a state ("no mechanical drift guard yet",
"nothing currently fails `make ci` if it drifts") that was no longer true, next to the
scripts that disprove it.

Verified directly (not assumed, ADR-0004): all three scripts exist
(`scripts/dependency-register-check.sh`, `scripts/dependency-concentration-sync-check.sh`,
`scripts/dependency-exit-runbooks-sync-check.sh`), all three have a `.PHONY` Makefile
target, and all three targets are invoked from the same `ci`-wired job (`Makefile`
lines 263-265, the `drift` target `make ci` runs). Confirmed by running `make ci`
locally after the edit — all three checks report green, plus every other drift
detector, with no gate weakened, skipped, or stubbed.

Fixed each file's "Keeping this in sync" section to state what's actually guarded and
what honestly still isn't:
- `docs/dependency-register.md`: "Last reviewed" staleness (register vs. cited ADRs'
  Re-evaluation logs) is guarded by `dependency-register-check.sh`; register→
  concentration.md org-count sync is guarded by `dependency-concentration-sync-check.sh`
  (one direction only — a concentration.md entry with no matching register rows is a
  real, separately-scoped gap, unchanged).
- `docs/dependency-concentration.md`: both its upstream sync (from the register) and
  downstream sync (to exit-runbooks.md) are now guarded, with the same honest
  one-direction-only caveats each script's own header comment already states.
- `docs/dependency-exit-runbooks.md`: the concentration-group half of its own sync is
  now guarded; the register single-tool-row half (7 of 11 `always-on-core` rows still
  uncovered — Terraform/Terragrunt, RabbitMQ, Valkey, KEDA, Forgejo,
  kube-state-metrics, node-exporter) remains a deliberate, documented scope choice,
  not drift, unchanged from before this fix.

No new mitigation invented — this is a documentation-accuracy fix only, closing the
gap between what these three files claimed and what `scripts/` + `Makefile` already
did. `make ci` stays green on every check, including the three sync-check gates whose
existence this PR documents accurately for the first time.

## PR

https://github.com/tooming/k8s-anywhere/pull/1381
