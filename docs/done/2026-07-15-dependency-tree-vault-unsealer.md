# docs/dependency-tree.md — document the vault-unsealer watchdog

ROADMAP rule #9's coverage/hardening fallback lane names "a doc page that's drifted
from the code it describes" as always-real, always-available work. Unlike
`README.md` and the Grafana "Lab UIs" panel, `docs/dependency-tree.md` has **no**
mechanical drift check (`make ci` has no `dependency-tree-check` target) — so a real
gap here was never going to be caught by CI, only found by reading.

Swept the doc against the actual `gitops/` tree for every ArgoCD `Application`
resource name and found one genuine, meaningful gap (most other apparent misses were
false positives — the doc's style covers `-extras`/`-networkpolicy`/`-schedules`
sub-Applications generically under their parent component, not by literal resource
name): `gitops/vault/unsealer.yaml`'s `vault-unsealer` Deployment — an always-running
watchdog that polls `vault status` and runs `vault operator unseal` whenever Vault
reports sealed, so Vault survives a pod restart or node reboot without a human
re-running `vault-bootstrap.sh` — had **zero** representation anywhere in the doc.
The day-0 bootstrap chain diagram only shows the *one-time* `vault-bootstrap.sh`
init/unseal/seed step; the *continuous* auto-unseal behavior (deployed via the
already-listed `vault-extras` Application) was invisible, which matters for a doc
whose whole purpose is showing how the lab's recoverability story (ADR-0005) actually
works.

## Changes

- `docs/dependency-tree.md`: added a `vaultunsealer` node to the `SEC` subgraph in the
  integration-graph diagram, plus a `vaultunsealer -.->|"poll status; unseal if
  sealed"| vault` edge in the secret-chain section.
- Added a **Notes** section bullet describing `vault-unsealer`'s behavior and — per
  ADR-0004 "never fabricate content, represent real trade-offs accurately" — its
  documented lab-only security caveat (the unseal key lives in a k8s Secret, so this
  drops seal protection to "whoever can read that Secret"; production would use a KMS
  auto-unseal instead), taken directly from the script's own header comment.

`make ci` passes (bats/lint locally; full suite in GitHub Actions).

(auto/dependency-tree-vault-unsealer)

## PR

https://github.com/tooming/k8s-anywhere/pull/417
