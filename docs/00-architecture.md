# Architecture & Learning Path

## The big idea

Every tool in this lab has a job in a single coherent system: a **GitOps-driven
Kubernetes platform**. Rather than learning components in isolation, you build one
platform where each tool occupies a clear role.

This lab went through a large, deliberate simplification 2026-09-06/2026-09-07: the
observability stack, Cilium, Garage, Forgejo, GitLab, Harbor, the DR front door,
capstone, Kyverno, Argo Rollouts, Velero, Trivy Operator, Kargo, ACK, and moto/KRO
were all removed entirely, no replacement — see each component's own ADR Status for
why. What's below describes the lab as it actually is today: a small, always-on
core with no on-demand components and no off-cluster services except Colima/Docker
itself.

## Platform layers

```
┌────────────────────────────────────────────────────────────────────────────┐
│  Bootstrap (IaC)                                                           │
│  Terraform · Terragrunt · k3d  — day-0 only; humans run this once         │
└──────────────────────────────────┬─────────────────────────────────────────┘
                                   │ creates cluster, installs ArgoCD
                                   ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  GitOps engine                                                             │
│  GitHub (public repo, git source of truth) ◄──── ArgoCD (app-of-apps)     │
│  ArgoCD watches gitops/ and converges the cluster to every commit          │
└──────────────────────────────────┬─────────────────────────────────────────┘
                                   │ sync-waves 0 → 1
                                   ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  Always-on in-cluster workloads (4 namespaces, nothing on-demand)          │
│                                                                            │
│  INGRESS      Traefik        (bundled with k3s; north-south traffic)       │
│  TLS          cert-manager  (auto-renewed certs from a self-signed CA)    │
│  POLICY       kube-router  (bundled NetworkPolicy enforcement, default-   │
│               deny per namespace — no separate policy engine)             │
│  DEMO         lab-demo  (single static hello-world Deployment)             │
└────────────────────────────────────────────────────────────────────────────┘
```

## Who does what

### Bootstrap (IaC)

| Tool | Role in the platform |
|------|----------------------|
| **k3s** (via **k3d**) | The Kubernetes cluster — k3d runs k3s inside Docker containers so the lab runs on a single Mac without a cloud account. Ships with Flannel (CNI) and kube-router (NetworkPolicy enforcement) bundled and enabled — no separate CNI install step. |
| **Terraform / Terragrunt** | Day-0 bootstrap only: creates the cluster and installs ArgoCD. Terragrunt keeps the Terraform modules DRY across environments. This is the *only* layer you run by hand — everything below is reconciled by ArgoCD. |

### GitOps engine

| Tool | Role in the platform |
|------|----------------------|
| **GitHub** | Git source of truth — this repo's own public remote. No self-hosted git source runs any more (Forgejo and GitLab were both removed entirely, no replacement); ArgoCD clones directly over HTTPS. |
| **ArgoCD** | GitOps engine. Watches GitHub and makes the cluster match it (app-of-apps pattern). All workloads below arrive via ArgoCD, never by `helm install` or `kubectl apply`. |

### Ingress

| Tool | Role in the platform |
|------|----------------------|
| **Traefik** | North-south ingress, bundled with k3s. External traffic enters via Traefik's own `IngressRoute` CRD; Traefik routes it to in-cluster Services. k3d's own load balancer publishes Traefik directly on the host at `:8080` — there is no separate front-door process any more (removed entirely 2026-09-07, no replacement). Per-app `allow-*-from-gateway` NetworkPolicy rules (sourced from kube-system) apply ADR-0016. (ADR-0040) |

### TLS / certificates

| Tool | Role in the platform |
|------|----------------------|
| **cert-manager** | Automated TLS certificate lifecycle — issues and auto-renews certs from a self-signed root CA (`k8s-lab-ca`), backing a wildcard `*.127.0.0.1.nip.io` Certificate. Every north-south route is reachable over both HTTP and Traefik's HTTPS listener; this is additive alongside the original HTTP-only path. `restricted` PSA, zero carve-out. (ADR-0028) |

### Secrets

Removed entirely 2026-09-07 ([ADR-0042](decisions/adr-0042-remove-vault-and-external-secrets.md),
supersedes ADR-0036/ADR-0037), no replacement — Vault (KV v2 secrets backend) and
External Secrets Operator (its Kubernetes-sync bridge) both had zero live
consumers left by the time they were cut; every credential the remaining
always-on stack needs (ArgoCD's admin password, every TLS certificate) is
natively generated in-cluster.

### Networking / policy

| Tool | Role in the platform |
|------|----------------------|
| **Flannel + kube-router** (bundled with k3s) | CNI and NetworkPolicy enforcement, replacing Cilium (removed entirely 2026-09-07, no replacement — ADR-0014). kube-router enforces standard `networking.k8s.io/v1 NetworkPolicy` post-DNAT (see [ADR-0016](decisions/adr-0016-default-deny-networkpolicy.md)'s "Cilium's removal" section for the enforcement-order detail); every always-on namespace still gets the same default-deny + allow-DNS-and-apiserver baseline, just enforced by a different mechanism. |

### Demo app

| Tool | Role in the platform |
|------|----------------------|
| **lab-demo** | A single static hello-world Deployment (`gitops/apps/demo/`) pulling straight from Docker Hub — the sole demo workload left in this lab (capstone, its more elaborate predecessor, was removed entirely, no replacement). |

> **Observability, removed 2026-09-06.** This lab used to run a full LGTM(P) stack
> (Grafana, Mimir, Loki, Tempo, Pyroscope) fed by an Alloy collector, plus
> kube-state-metrics and node-exporter as scrape targets. It was removed entirely
> with no replacement — [ADR-0041](decisions/adr-0041-remove-observability-stack.md)
> (supersedes [ADR-0006](decisions/adr-0006-grafana-native-git-sync.md) and
> [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md)) has the full
> reasoning. There is no dashboard/metrics/logs/traces layer in this lab any more.

## The GitOps flow (worth internalising)

1. You change a manifest in `gitops/` and push to **GitHub**.
2. **ArgoCD** notices the commit and compares it to the live cluster.
3. ArgoCD applies the diff — the cluster converges to match git.
4. **You never `kubectl apply` workloads by hand;** git is the only way in.

Terraform/Terragrunt is the exception: it builds the *foundation* that GitOps then runs on. Rule of thumb — **Terraform builds the platform, ArgoCD runs on the platform.**

## Suggested learning path

0. **Toolchain + Colima** — container runtime VM. Set up first.
1. **Foundation** — `make up` (k3d + ArgoCD + GitHub wiring). The whole lab rebuilds from this one command.
2. **Core platform** — Traefik routes traffic; cert-manager issues and auto-renews the TLS certs Traefik's TLSStore serves from a self-signed root CA.
3. **Cloud-agnostic infrastructure design** — read [`infra/live/README.md`](../infra/live/README.md): the `argocd` Terragrunt unit depends only on the `cluster` unit's `kube_context`/`cluster_name`/`api_endpoint` outputs, never on which backend produced them, which is why step 1 above runs identically whether `cluster/` is `local/` (k3d, this lab's default) or `oracle/` (Oracle Cloud Always Free + k3s, see [ADR-0026](decisions/adr-0026-cloud-agnostic-infrastructure.md) and [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md)). The lesson: portability is a property of *where the Terraform bootstrap seam sits*, not something bolted on afterward — GitOps state in `gitops/` never needs to know or care where the cluster runs.

Every step this lab's learning path used to cover past step 3 — observability,
a data layer (RabbitMQ/Valkey/KEDA), cloud control-plane patterns (moto/ACK/KRO),
supply-chain security (Kyverno/Trivy Operator), progressive delivery (Argo
Rollouts), stateful backup/restore (Velero), blue-green DR, and GitOps promotion
pipelines (Kargo) — was removed entirely, no replacement, across a series of
2026-09-06/2026-09-07 removals. See each component's own ADR Status for what it
used to demonstrate and why it's gone; this is not a temporary gap to be
"finished" later, it's the maintainer's deliberate current shape for this lab.
