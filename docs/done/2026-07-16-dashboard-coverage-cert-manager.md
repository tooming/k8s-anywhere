# O5 dashboard-coverage sweep — cert-manager gap

Coverage/hardening fallback per ROADMAP rule #9: all 5 remaining `Now / next` items are
gated on live-cluster maintainer confirmations, and the two real split-the-gate slices
of `auto/harbor-capstone-rewire` (`auto/harbor-registry-secret-prep`,
`auto/harbor-kargo-egress-prep`) are already shipped — re-checked and found no further
splittable piece of any gated item. The only open 🟡 item (vault PSA-restricted) is
explicitly a no-op until an external chart change. Fell back to a genuine coverage sweep
rather than declaring nothing to do.

## Gap found

CHARTER **Objective O5** ("every Application in `gitops/bootstrap/root-app.yaml`'s
auto-synced set has a matching `grafana/dashboards/lab-<name>.json`... measured by a
drift check wired into `make ci`") is implemented by `tests/dashboard-coverage.bats` — a
hand-maintained sweep, one existence + datasource-uid assertion pair per always-on
component. Diffed every `grafana/dashboards/lab-*.json` file against that sweep: five
components were missing (`harbor`, `inkless`, `kargo`, `longhorn`, `tidb`), but all five
are legitimately out of O5's scope — each is manual-sync only (`syncPolicy` has no
`automated:` block), so they're on-demand, not part of the *auto-synced* set O5 measures.
`cert-manager` was the one real gap: its five Applications
(`cert-manager`/`-extras`/`-networkpolicy`/`-root-ca`, plus `lab-gateway-certificate`
from the Gateway HTTPS follow-up, #440) are all `automated: {prune: true, selfHeal:
true}` — genuinely always-on — and `lab-cert-manager.json` already exists with real
Mimir panels (shipped in #439), but the sweep file itself was never updated to assert
it, so `make ci` wasn't actually enforcing O5 for this component.

## What shipped

Two new cases in `tests/dashboard-coverage.bats`, following the file's existing
one-section-per-component pattern exactly: `lab-cert-manager.json exists` and
`lab-cert-manager.json has real Mimir datasource panel (ADR-0004)`.

## Verification

`bats tests/dashboard-coverage.bats` — 54/54 pass. Full `make ci` green.

## PR

https://github.com/tooming/k8s-anywhere/pull/442
