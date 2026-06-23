- [ ] 🟢 **PSA baseline + NetworkPolicy — `inkless` namespace** (CHARTER **Objective O2**,
  due **2026-09-30**; RFC #257 — architect decision 2026-06-23; closes O2 fan-out for the
  last on-demand namespace missing PSA labels and a NetworkPolicy floor). Two changes
  bundled (both small, same shape as `auto/pss-np-lab-demo`): (a) **PSA labels** — add
  `gitops/inkless/namespace.yaml` with all four PSA labels at `baseline` (`enforce:
  baseline`, `enforce-version: latest`, `warn: baseline`, `audit: baseline`). The Aiven
  Inkless broker (`ghcr.io/aiven/inkless:latest`) runs as root UID 0 (no USER directive
  in the base image); `baseline` is the correct profile. Add new auto-synced `Application`
  `gitops/platform/inkless-extras.yaml` (sync-wave 0, `ServerSideApply=true`,
  `CreateNamespace=false` — namespace pre-created by `make inkless-up`; follows the
  `argocd-extras` / `kyverno-extras` naming convention). Add `inkless → baseline` row to
  ADR-0017 §"Per-namespace profile" table citing RFC #257; document flip condition to
  `restricted` (when `ghcr.io/aiven/inkless` ships with explicit non-root USER directive).
  (b) **NetworkPolicy** — add
  `gitops/inkless/networkpolicy/kustomization.yaml` referencing the two shared baseline
  templates (`../../network/policies/default-deny.yaml`,
  `../../network/policies/allow-dns-and-apiserver.yaml`) plus three allow files:
  `allow-inkless-intra-namespace.yaml` (ingress+egress `podSelector: {}` within the
  `inkless` namespace — covers broker↔postgres JDBC on TCP 5432, kafka-load→broker on TCP
  9092, KRaft internal TCP 19092/29090); `allow-inkless-garage-egress.yaml` (egress TCP
  3900 to `namespaceSelector: kubernetes.io/metadata.name: storage` — inkless broker
  streams topic segments to Garage S3 per ADR-0002); `allow-inkless-metrics-ingress.yaml`
  (ingress TCP 9308 from `namespaceSelector: kubernetes.io/metadata.name: observability`
  — Alloy kafka-exporter scrape already wired in `observability-alloy.yaml`). Add
  `inkless-networkpolicy` entry to `networkpolicy-appset.yaml` list generator (`gitPath:
  gitops/inkless/networkpolicy`, `destNamespace: inkless`); sync policy is `automated:
  {prune: true, selfHeal: true}` via the appset template (same as tidb pattern — NP is
  cheap; in place before `make inkless-up` brings pods up). Extend
  `tests/securitycontext.bats`: `gitops/inkless/namespace.yaml` exists; `enforce:
  baseline` present; `enforce: restricted` absent (safety check). Extend
  `tests/networkpolicy.bats`: kustomization exists; baseline refs present; each allow file
  exists targeting the documented port + selector; appset entry `inkless-networkpolicy`
  present. `docs/done/` entry required. `make ci` must pass. (auto/pss-np-inkless)
