# Pin k3s to an explicit version on every backend

(CHARTER **Core Values** §"Recreate-from-code" + §"Clusterless gates stay green";
RFC/issue #558 — architect decision 2026-07-19, new
[ADR-0030](../decisions/adr-0030-pin-k3s-version-explicitly.md) (no existing ADR
governed k3s's version — adopted directly per WAYS-OF-WORKING.md §0.1/§2). No
prerequisites — executor picked up immediately.)

Neither backend pinned a k3s version before this change: `infra/modules/k3d-cluster/
k3d-config.yaml.tftpl` had no `image:` key (k3d used whatever's bundled with the
installed CLI), and `infra/modules/oracle-k3s-cluster/cloud-init.yaml` installed via
`curl -sfL https://get.k3s.io | sh -` with no `INSTALL_K3S_VERSION` (always fetched
current `stable`). This broke CHARTER's "recreate-from-code" Core Value (two `make up`
runs months apart weren't reproducing the same lab) and meant k3s — the most
privileged layer in the stack — had no recorded version for the architect's weekly
CVE sweep to check against (the concrete trigger: CVE-2026-54250, K3s ZIP path
traversal in etcd-snapshot decompression, fixed in `1.33.10`/`1.34.6`/`1.35.3`).

Pinned **`v1.36.2+k3s1`** on both backends, per ADR-0030's grounding (git tag +
Docker Hub image both directly verified, comfortably past CVE-2026-54250's fix
lines):

- `infra/modules/k3d-cluster/k3d-config.yaml.tftpl`: added a top-level
  `image: rancher/k3s:v1.36.2-k3s1` key (hyphen tag format — a documented top-level
  field of k3d's own `k3d.io/v1alpha5` `Simple` config schema, sibling to the
  existing `servers`/`agents`/`kubeAPI`/`ports`/`options` keys).
- `infra/modules/oracle-k3s-cluster/cloud-init.yaml`: changed the install line to
  `curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.36.2+k3s1 sh -` (`+` tag
  format — different from the Docker Hub tag's hyphen; both files carry an inline
  comment cross-referencing the other so a future bump doesn't update one and
  forget the other).
- `docs/decisions/context.md`: updated the stale "k3s v1.33.6, 2 nodes" descriptive
  line to "k3s v1.36.2+k3s1 (pinned, ADR-0030), 2 nodes".
- New `tests/k3s-version-pin.bats` (9 assertions, fully clusterless — no
  `terraform apply`, no cluster): both backends pin an explicit version (not left to
  a CLI/installer default); both pin the exact expected version in the correct tag
  format each; both pins parse to the *same* numeric version (the actual recurrence
  guard — a future bump that updates one backend and forgets the other's different
  tag format fails this test); the stale context.md line is gone and the new one is
  present; ADR-0030 exists.

**ADR-0004 caveat:** this is a Terraform-bootstrap-seam change (ADR-0001's boundary —
never workload/GitOps) that this remote clusterless session cannot verify against a
live `make up` or a real Oracle instance launch (the Oracle path is separately still
blocked on an unrelated Always Free capacity constraint, per `infra/live/README.md`).
Live verification is pending the maintainer's next local `make up` / cloud apply —
not claimed as exercised here.

`make ci` passes (bats/shellcheck/yamllint all installed this session for full local
verification; `terraform` itself not installed locally, so `validate-terraform.sh`
skips locally same as always and runs in GitHub Actions CI — this change only touches
a `.tftpl` template's content and a cloud-init YAML, not any `.tf` HCL syntax).
Confirmed zero new failures via the same pre-existing-failure baseline established
earlier this run. Closes #558.

## PR

[#561](https://github.com/tooming/k8s-anywhere/pull/561)
