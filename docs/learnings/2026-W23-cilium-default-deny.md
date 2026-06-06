# Week 2026-W23: Default-deny NetworkPolicy — why Flannel can't help you

## What landed

- **PR #95** (`arch/cilium-prerequisite-rfc82`, 2026-06-03) — ADR-0014 merged. Swaps the lab's CNI from k3s-bundled Flannel to Cilium, disabling Flannel at bootstrap time via `disable_default_cni` in the Terragrunt config. Merged the ADR doc and updated the k3d cluster template.
- **PR #112** (`auto/cilium-manifest-infra-flip`, 2026-06-05) — Cilium management moved from Terraform-only into GitOps: `gitops/platform/cilium.yaml` (ArgoCD `Application`, non-auto-synced), `make cilium-up` / `make cilium-down` targets, `tests/cilium.bats`, and dependency-tree / DR docs updated.
- **PR #117** (`auto/networkpolicy-data-pilot`, 2026-06-05) — First live default-deny overlay: `gitops/data/networkpolicy/` adds a `default-deny-all` + `allow-dns-and-apiserver` baseline to the `data` namespace, plus per-workload allow rules for RabbitMQ ingress, Valkey ingress, and data-demo egress (ADR-0016 pilot).

## The concept it taught

**Why a NetworkPolicy is silent without a policy-capable CNI.**
Kubernetes `NetworkPolicy` objects are just data — they sit in etcd and mean nothing unless the CNI plugin reads them and programs the dataplane accordingly. k3s ships Flannel, a pure layer-2 overlay that moves packets between nodes but implements no NetworkPolicy enforcement. You can `kubectl apply` a thousand `NetworkPolicy` objects onto a Flannel cluster and every pod can still reach every other pod. This is the ADR-0004 problem applied to networking: fabricated security posture, not actual security posture.

Cilium solves this by replacing both the network fabric and the policy engine with a single eBPF-based component that compiles `NetworkPolicy` rules directly into the kernel's packet filter. The swap is not additive — you cannot run Flannel and Cilium side by side. So it must happen at cluster creation time (`--flannel-backend=none --disable-network-policy` passed to the k3s server args). ADR-0014 captures why this is a bootstrap-time, not a runtime, change.

**What default-deny actually means in practice.**
The two-policy baseline from ADR-0016 (`default-deny-all` + `allow-dns-and-apiserver`) establishes a zero-trust floor: every pod in a namespace is denied all ingress and egress *except* DNS lookups and API server access, which are necessary for any workload to function. Everything else — RabbitMQ AMQP ingress, Valkey TCP ingress, scrape paths for exporters, inter-namespace traffic — must be explicitly allowed via named `NetworkPolicy` objects. The cost is verbosity; the benefit is that a compromised pod cannot reach anything it wasn't already authorised to reach, regardless of what port it tries. PR #117 applies this to the `data` namespace as a pilot before the planner fans the pattern out to remaining namespaces.

## One pointer for further reading

Kubernetes NetworkPolicy documentation, including the precise semantics of `podSelector: {}` (match all pods) and the interaction between multiple policies: <https://kubernetes.io/docs/concepts/services-networking/network-policies/>
