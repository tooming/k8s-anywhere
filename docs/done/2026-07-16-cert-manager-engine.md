# cert-manager engine + self-signed root CA bootstrap (new CHARTER Goal)

**Genuinely new architect-tier feature work**, per direct maintainer request after the
session's fallback-chain governance fix (see
`docs/done/2026-07-16-harbor-registry-secret-prep.md`): "scope genuinely new feature
work... make sure this never happens again." This entry is the "make sure this never
happens again" follow-through — not another coverage/hardening pickup, a real new
capability with its own ADR.

## Gap found

Every north-south route in the lab is plain HTTP — `http://<name>.127.0.0.1.nip.io:8000`.
No TLS anywhere in the ingress path (`gitops/network/gateway.yaml` declares a single
`protocol: HTTP` listener), and cert-manager is explicitly *avoided* elsewhere in the
repo today (`gitops/platform/tidb-operator.yaml`'s own comment: "Skip admission webhook
— avoids cert-manager dependency in a lab"). No ADR had ever evaluated TLS automation.
Against the CHARTER Vision ("the most complete production-shaped cloud-native
platform"), this is a real, substantial gap — not a testing/coverage gap, a genuine
missing platform capability.

## What shipped

**New `docs/decisions/adr-0028-cert-manager-tls-lifecycle.md`** (architect decision,
self-authorizing per WAYS-OF-WORKING.md §0.1/§2 — new ground, not a supersession):
adopts cert-manager, chart `cert-manager` v1.20.3 from `https://charts.jetstack.io`,
self-signed root CA (not public ACME — neither the localhost default nor the Oracle
cloud backend is internet-reachable in a way real ACME could use, so a self-signed
root works identically on both, matching ADR-0026's cloud-agnostic-by-construction
principle). Verified directly against the pinned chart's real `values.yaml` (fetched
via the sparse-clone technique this ROADMAP already documents for proxy-blocked Helm
repo indexes) that the controller/webhook/cainjector **all default to the full PSS
`restricted` profile with no override needed** — unusual for a first-cut component in
this lab, and confirmed the CRDs are large enough (~325 KB) to need `ServerSideApply=true`,
the same failure class ADR-0019 hit for Kyverno.

**New CHARTER.md content**: a Goal ("automated TLS certificate lifecycle") and a
Target end-state entry, both citing ADR-0028.

**Split into a buildable-now item and an explicitly-deferred follow-up**, per the same
live-state-mutating framework the session's governance fix established:
- **Built now (this PR)**: the cert-manager engine itself (auto-synced Application,
  namespace with zero-carve-out `restricted` PSA, default-deny NetworkPolicy overlay,
  Alloy scrape job, Grafana dashboard) plus the self-signed root-CA bootstrap chain
  (`selfsigned-bootstrap` ClusterIssuer → root `Certificate` → `k8s-lab-ca` ClusterIssuer).
  Verified by a dedicated bats assertion that nothing outside `gitops/cert-manager/`
  references the new issuer chain yet — purely additive, zero live-traffic-path change.
- **Explicitly deferred** (ADR-0028 §"Scope & exceptions", follow-up ROADMAP item): a
  new HTTPS listener on the existing shared Gateway, a wildcard Certificate for
  `*.127.0.0.1.nip.io`, and the `frontdoor` tooling's `:8443` port mapping — additive
  alongside the current HTTP listener, never a breaking cutover, but scoped as its own
  ~400-line-budget item rather than bundled here.

**Manifests**: `gitops/platform/cert-manager.yaml` (+`-extras`, `-networkpolicy`,
`-root-ca`), `gitops/cert-manager/namespace.yaml`, `gitops/cert-manager/networkpolicy/`,
`gitops/cert-manager/root-ca/` (three CRs). `gitops/platform/observability-alloy.yaml`
new `cert_manager` scrape job. `grafana/dashboards/lab-cert-manager.json` (9 panels,
real `certmanager_certificate_*` series only, ADR-0004).

**Bats coverage**: `tests/cert-manager.bats` (39 cases: Application shape, chart pin,
CRD install mode, footprint limits, ServerSideApply, PSA labels, NetworkPolicy overlay,
the three-resource root-CA chain, the "not referenced outside gitops/cert-manager/"
additive-only proof, scrape job, dashboard). Plus the two O2 recurrence-guard files
every new PSA-labelled/NetworkPolicy-overlaid namespace requires:
`tests/securitycontext-cert-manager.bats` and `tests/networkpolicy-cert-manager.bats`
(caught locally by `make ci` — two guard failures on the first run, both closed by
adding these files rather than weakening the guards).

**Docs**: `docs/dependency-tree.md` (wave table rows 0/1/4/5 + a full component
description paragraph), `docs/decisions/adr-0017-pod-security-standards-restricted.md`
(new `cert-manager: restricted` row, zero-carve-out), `docs/decisions/README.md` (ADR
index entry), `README.md` (new "TLS / certificates" stack-table row).

## Real bugs caught during research (before any manifest was written)

Fetched the pinned chart's actual template files (not just values.yaml comments) via
git sparse-checkout before committing to any port number in the ADR:
- Initially assumed the webhook callback port was 6443/443 (typical apiserver-adjacent
  ports); the chart's actual default is `webhook.securePort: 10250`. Caught by grepping
  the real `values.yaml`, not by guessing — fixed in both the ADR and the ROADMAP item
  before any NetworkPolicy was written, so the manifests were correct on the first pass.
- Confirmed the metrics port (9402) and the full `restricted`-compatible securityContext
  defaults the same way — verified claims, not assumed ones, per ADR-0004's spirit
  extended to architecture-decision research, not just dashboard content.

## Verification

Full local `make ci`: 1961 bats assertions, 0 failures (after adding the two O2
recurrence-guard files the first run caught). `bash scripts/validate-manifests.sh`
(kubeconform) and `validate-kustomize.sh` both pass. `shellcheck`/`yamllint` clean.
`charts.jetstack.io` is proxy-blocked in this sandbox (same class as other Helm repo
indexes noted earlier in this ROADMAP) — `helm-chart-pin-check.sh` and
`argocd-crd-ssa-check.sh` both degrade to a tolerant skip for this one chart, exactly
as designed; the chart version itself (1.20.3) was confirmed to exist via
`git ls-remote --tags` against the chart's own git repo, which is reachable.

## PR

Autonomous session run — see the `claude/work-until-credits-exhausted-b828b2` branch.
