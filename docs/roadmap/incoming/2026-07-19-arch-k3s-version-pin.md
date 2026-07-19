- [ ] 🟢 **Pin k3s to an explicit version on every backend** (CHARTER **Core Values**
  §"Recreate-from-code" + §"Clusterless gates stay green"; RFC/issue #558 — architect
  decision 2026-07-19, new [ADR-0030](../../decisions/adr-0030-pin-k3s-version-explicitly.md)
  (no existing ADR governed k3s's version — adopted directly per WAYS-OF-WORKING.md
  §0.1/§2). **No prerequisites — executor may pick up immediately.**) Neither backend
  pins a k3s version today: `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` has no
  `image:` key (k3d uses whatever's bundled with the installed CLI), and
  `infra/modules/oracle-k3s-cluster/cloud-init.yaml` installs via
  `curl -sfL https://get.k3s.io | sh -` with no `INSTALL_K3S_VERSION` (always fetches
  current `stable`). This broke CHARTER's "recreate-from-code" Core Value (two `make up`
  runs months apart aren't reproducing the same lab) and meant k3s — the most privileged
  layer in the stack — had no recorded version for the architect's weekly CVE sweep to
  check against (the concrete trigger this pass: CVE-2026-54250, K3s ZIP path traversal
  in etcd-snapshot decompression, fixed in `1.33.10`/`1.34.6`/`1.35.3` — whether this lab
  was affected was unanswerable with no pin on record).

  Pin **`v1.36.2+k3s1`** on both backends — verified directly (not assumed, ADR-0004):
  the git tag is real (corroborated via a second independent source alongside the
  latest `1.34.x`/`1.35.x` patches, confirming `1.36.2` is genuinely the current stable
  line), and the `rancher/k3s:v1.36.2-k3s1` Docker Hub image was **positively confirmed**
  via Docker Hub's real tags API (`tag_status: active`, multi-arch, real digest and
  `last_updated` timestamp) — a direct registry check, not an indirect inference.
  Comfortably past CVE-2026-54250's fix lines on every supported branch.

  Add `image: rancher/k3s:v1.36.2-k3s1` (hyphen tag format) as a new top-level key in
  `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` — `image` is a documented top-level
  field of k3d's own `k3d.io/v1alpha5` `Simple` config schema, sibling to the existing
  `servers`/`agents`/`kubeAPI`/`ports`/`options` keys already in that file. Change
  `infra/modules/oracle-k3s-cluster/cloud-init.yaml`'s install line to
  `curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.36.2+k3s1 sh -` — note the
  **different tag format** (`+` here vs. the Docker Hub tag's hyphen — a real footgun,
  see ADR-0030's "Tag-format note"). Update `docs/decisions/context.md`'s stale
  "k3s v1.33.6, 2 nodes" line to reflect the pin. Add `tests/k3s-version-pin.bats`
  (clusterless — no `terraform apply`, no cluster) asserting both backends reference
  `v1.36.2+k3s1`/`v1.36.2-k3s1` respectively (the correct format each) — a recurrence
  guard so a future bump that updates one backend and forgets the other's different tag
  format fails `make ci`, mirroring this repo's existing per-component pin-assertion
  pattern (`argo-rollouts.bats`'s `targetRevision` checks, etc.).

  **ADR-0004 caveat, carry into the PR body:** this is a Terraform-bootstrap-seam change
  (ADR-0001's boundary — never workload/GitOps) that this remote clusterless session
  cannot verify against a live `make up` or a real Oracle instance launch (the Oracle
  path is separately still blocked on an unrelated Always Free capacity constraint per
  `infra/live/README.md`). State plainly in the PR that live verification is pending the
  maintainer's next local `make up` / cloud apply — do not claim it was exercised.
  `make ci` (terraform fmt/validate, no live apply) must pass. `docs/done/` entry
  required. Closes #558. (auto/k3s-version-pin)
