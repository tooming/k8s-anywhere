# Dependency & integration tree

How every piece of the lab depends on and integrates with every other piece.
Derived from the GitOps source of truth (sync-wave annotations, `ExternalSecret`
`remoteRef`s, `IngressRoute`s, the bootstrap scripts and `make up`), so it matches what
ArgoCD reconciles into the cluster. Two views: the **runtime integration graph** and
the **day-0 bootstrap chain**.

As of 2026-09-07 this lab is down to exactly 6 always-on namespaces, no on-demand
components, and no off-cluster services except Colima/Docker itself — a large,
deliberate simplification (Cilium, Garage, Forgejo, GitLab, Harbor, the DR front
door, capstone, Kyverno, Argo Rollouts, Velero, Trivy Operator, Kargo, ACK, moto,
and KRO were all removed, no replacement, alongside the observability stack
removed the day before, ADR-0041). This file describes only what's actually live
today; see each component's own ADR Status for what used to be here and why it's
gone.

## Integration graph (who talks to whom)

```mermaid
graph TD
  classDef boot fill:#ffe0ef,stroke:#b3598a,color:#000
  classDef gitops fill:#dceeff,stroke:#3b78b3,color:#000
  classDef sec fill:#fff6cc,stroke:#b39b00,color:#000
  classDef ing fill:#ffe6ff,stroke:#b35bb3,color:#000

  user(["You — browser"])

  subgraph HOST["Host / runtime"]
    colima["Colima VM (qemu, 12G)"]
    dockerd["Docker daemon"]
    colima --> dockerd
  end

  subgraph BOOT["Day-0 bootstrap — imperative (Terraform/Terragrunt + scripts)"]
    tg["Terragrunt"]
    scripts["scripts: vault-bootstrap"]
  end

  github["GitHub — git source of truth<br/>(public remote, no self-hosted git)"]:::boot
  k3d["k3d cluster (k3s-in-Docker)<br/>bundled Flannel CNI + kube-router NetworkPolicy"]:::boot
  argocd["ArgoCD — GitOps engine"]:::gitops

  dockerd --> k3d
  tg -->|creates| k3d
  tg -->|helm install| argocd
  argocd -->|"clone directly (HTTPS, public repo)"| github
  scripts -->|init/unseal/seed| vault
  argocd ==>|"app-of-apps · sync-waves 0-2"| AOA

  subgraph AOA["In-cluster workloads — ArgoCD-managed"]
    subgraph SEC["Secrets"]
      vault["Vault (KV v2)"]:::sec
      vaultunsealer["vault-unsealer<br/>auto re-unseal watchdog<br/>(lab-only: key in k8s Secret)"]:::sec
      eso["External Secrets Operator<br/>ClusterSecretStore 'vault'"]:::sec
    end
    subgraph CERTMANAGER["cert-manager — always-on (cert-manager ns, ADR-0028)"]
      certmanagerctrl["cert-manager controller<br/>TLS lifecycle + root CA chain<br/>(metrics :9402)"]:::gitops
    end
    traefik["Traefik (bundled with k3s)<br/>k3d LB publishes :8080 on the host"]:::ing
    demo["lab-demo — hello-world Deployment<br/>(HotROD image, Docker Hub)"]:::gitops
  end

  %% --- secret chain (ExternalSecret <- Vault path) ---
  vaultunsealer -.->|"poll status; unseal if sealed"| vault
  vault -->|"k8s auth, role eso"| eso

  %% --- cert-manager TLS lifecycle ---
  certmanagerctrl -.->|"issues k8s-lab-ca wildcard cert"| traefik

  %% --- ingress (north-south) ---
  user -->|":8080 (k3d LB, no separate front door)"| traefik
  traefik -->|argocd.127.0.0.1.nip.io| argocd
  traefik -->|vault.127.0.0.1.nip.io| vault
  traefik -->|lab-demo.127.0.0.1.nip.io| demo
```

## Day-0 bootstrap chain (`make up` — the only imperative steps)

Everything below step 5 is reconciled by ArgoCD straight from GitHub (no
self-hosted git source any more); steps 1–5 are the non-GitOps seam (you can't
GitOps the GitOps engine into being).

```
make up
└─ 1 colima-up            Colima VM (Docker runtime)
   └─ 2 cluster-up            k3d cluster (bundled Flannel + kube-router)  [Terragrunt]
      └─ 3 coredns-host-alias     host.k3d.internal -> docker gateway     [scripts/coredns-host-alias.sh]
         └─ 4 argocd                 ArgoCD (GitOps engine)               [Terraform/Helm]
            └─ 5 root-app               app-of-apps planted               [kubectl apply]
               ├─ 6 coredns-nip-io-rewrite  *.127.0.0.1.nip.io -> Envoy    [scripts/coredns-host-alias.sh]
               └─ 7 vault-bootstrap         init/unseal; k8s auth + eso role; kick ESO
                  └─ ESO syncs Vault→Secrets for any Application that needs one
```

> **No off-cluster services left.** Cilium, Garage (in-cluster + the off-cluster
> tfstate backend), Forgejo, and the DR front door were each an off-cluster or
> pre-ArgoCD bootstrap dependency in this lab's earlier, larger shape — all were
> removed entirely 2026-09-07, no replacement. `make up` now only ever talks to
> Colima/Docker, k3d/Terraform, and ArgoCD/GitHub — no docker-compose stack, no
> second Terraform state backend, and no CNI install step before ArgoCD.

## ArgoCD apply order (sync-waves, from `gitops/platform/`)

| Wave | Apps | Why this wave |
|------|------|---------------|
| 0 | demo, cert-manager-extras, external-secrets-extras, argocd-extras | Traefik itself needs no ArgoCD Application (bundled with k3s, ADR-0040); demo (no wave annotation, auto-synced); cert-manager-extras (namespace PSA restricted labels before the Helm release — ADR-0028); external-secrets-extras (namespace PSA restricted labels before the external-secrets Helm release — RFC #229); argocd-extras (SSA-patches full PSA `restricted` labels onto the Terraform-created `argocd` namespace, RFC #205 — ADR-0017 §Staged rollout Phase 2) |
| 1 | vault, external-secrets, lab-gateway, cert-manager | secret engine + ESO controller; shared Gateway namespace scaffolding (no separate Gateway API CRDs any more, Traefik's own `IngressRoute` CRD is bundled); cert-manager TLS certificate lifecycle manager + CRDs (ADR-0028) |
| 2 | external-secrets-config, vault-extras | ClusterSecretStore + ESO bindings; Vault add-ons (vault-unsealer watchdog) |
| — | networkpolicy, governance ApplicationSets (wave 3, generated Applications at wave 4) | Plant one per-namespace NetworkPolicy + LimitRange Application per always-on namespace — `argocd`, `cert-manager`, `external-secrets`, `lab-demo`, `lab-gateway`, `vault` |
| — | cert-manager-root-ca (wave 5), lab-gateway-certificate (wave 6) | Self-signed root CA chain, then the wildcard `*.127.0.0.1.nip.io` Certificate for Traefik's HTTPS listener |

> Sync-waves are ArgoCD's **apply** order. The **runtime** secret dependency
> (Vault must be *bootstrapped* before ESO can sync) is enforced by the day-0
> chain above, not by waves — which is why `vault-bootstrap` kicks ESO.

## Integration edges, grounded

| Edge | Type | Source of truth |
|------|------|-----------------|
| ArgoCD → GitHub | HTTPS clone, public repo, no deploy key needed | Terraform `argocd` module / root Application `repoURL` |
| Vault → ESO | k8s auth, role `eso`, policy `eso-read` | `scripts/vault-bootstrap.sh` |
| Host :8080 → Traefik → UIs | k3d's own load balancer publishes Traefik's `web` entrypoint directly on the host — no separate front-door process (removed entirely 2026-09-07, no replacement) | `infra/modules/k3d-cluster/variables.tf` (`http_port`), per-app `IngressRoute`s |
| cert-manager → Traefik | issues `k8s-lab-ca` wildcard cert, terminated by Traefik's `TLSStore` | `gitops/network/certificates/wildcard-certificate.yaml` |

## Notes

- **Front door removed 2026-09-07, no replacement.** The off-cluster nginx proxy
  that used to sit in front of Traefik on `:8000` (and the blue/green DR drill it
  enabled) is gone entirely. Every UI is now reached directly through k3d's own
  load balancer on **`:8080`** — the port `infra/modules/k3d-cluster/variables.tf`'s
  `http_port` publishes on the host. There is no longer a stable port that
  survives a cluster recreate independent of the k3d LB itself; recreating the
  cluster is the only "DR" story left (see [docs/DR.md](DR.md)).
- **vault-unsealer** (`gitops/vault/unsealer.yaml`, deployed via the auto-synced
  `vault-extras` Application) is a small always-running watchdog Deployment in the
  `vault` namespace — separate from the one-time `vault-bootstrap.sh` init/unseal/seed
  step shown in the day-0 bootstrap chain above. It polls `vault status` and runs
  `vault operator unseal` whenever Vault reports sealed, so Vault comes back
  auto-unsealed after every pod restart or node reboot without a human re-running the
  bootstrap script — the ADR-0005 "recreate from code" recoverability story for Vault
  specifically. **Lab-only trade-off** (per the script's own header comment): the
  unseal key lives in the `vault-keys` Kubernetes Secret, so this drops seal
  protection to "whoever can read that Secret" — a production deployment would use a
  KMS auto-unseal (e.g. `seal "awskms"`) instead.
- **cert-manager** (`gitops/platform/cert-manager.yaml` + `gitops/platform/cert-manager-extras.yaml`) is **always-on / auto-synced** — TLS certificate lifecycle manager (chart `cert-manager` v1.21.1 from `https://charts.jetstack.io`, namespace `cert-manager`). ADR-0028. Single-replica per component (ADR-0005 lab trade-off); controller/webhook/cainjector all default to the full PSS `restricted` profile with no chart override. `cert-manager-extras` (wave 0) pre-creates the namespace with PSA `restricted` labels. The `cert-manager` Helm Application (wave 1) ships the engine + CRDs (`ServerSideApply=true`, its CRDs are over the client-side-apply annotation cap). `cert-manager-networkpolicy` applies the default-deny overlay (ADR-0016). `cert-manager-root-ca` (wave 5) bootstraps a self-signed root CA via the standard two-`ClusterIssuer` chain (`selfsigned-bootstrap` → root `Certificate` → `k8s-lab-ca`) — chosen over public ACME because neither backend (localhost or the Oracle cloud instance) is internet-reachable in a way real ACME could use (ADR-0026). The shared `TLSStore` (`gitops/network/traefik-tls-store.yaml`, ADR-0040) terminates TLS with the wildcard `*.127.0.0.1.nip.io` Certificate, delivered by the auto-synced `lab-gateway-certificate` Application at wave 6. Every `IngressRoute` opts in with an empty `tls: {}` stanza.
- **lab-demo namespace PSA baseline + NetworkPolicy** (`gitops/apps/demo/namespace.yaml` + `gitops/apps/demo/networkpolicy/`) — PSA `baseline` labels and default-deny NetworkPolicy floor for the `lab-demo` namespace (ADR-0016 §4 fan-out + ADR-0017 §Per-namespace profile). `baseline` (not `restricted`) because the upstream `jaegertracing/example-hotrod` image runs as root. No ingress allow needed beyond the baseline plus Traefik's own route. Namespace manifest is picked up by the existing `demo` ArgoCD Application (`gitops/platform/demo.yaml`, wave 0).
- **argocd namespace network policy** (`gitops/argocd/networkpolicy/`) — default-deny-all + allow-dns-and-apiserver baseline policies applied to the `argocd` namespace (ADR-0016 §4 fan-out). Explicit allow policies permit: ingress from Traefik's data-plane pods in `kube-system` to `argocd-server` on TCP 8080 (for the `argocd.127.0.0.1.nip.io` IngressRoute); broad intra-namespace allow-all covering all ArgoCD component-to-component flows (`allow-argocd-intra-namespace.yaml`); egress from `argocd-repo-server` to public Helm/OCI chart registries on TCP 443 (`allow-argocd-repo-server-egress-charts.yaml`) and to GitHub itself for the git clone. Deployed by the auto-synced `argocd-networkpolicy` Application (via `networkpolicy-appset.yaml`, wave 4).
- **argocd namespace PSS Phase 1 + Phase 2** (ADR-0017 §Staged rollout, RFC #205) — `gitops/argocd/namespace.yaml` carries all four PSA labels at `restricted`. Delivered by the auto-synced `argocd-extras` ArgoCD Application (`gitops/platform/argocd-extras.yaml`, sync-wave 0, `ServerSideApply=true`, `CreateNamespace=false`).
- **vault namespace network policy** (`gitops/vault/networkpolicy/`) — default-deny-all + allow-dns-and-apiserver baseline policies applied to the `vault` namespace (ADR-0016 §4 fan-out; protects the secrets plane). Explicit allow policies permit: ingress from ESO controller pods in `external-secrets` (TCP 8200, `allow-vault-from-eso.yaml`); ingress from Traefik's data-plane pods in `kube-system` (TCP 8200, for the `vault.127.0.0.1.nip.io` IngressRoute — `allow-vault-from-gateway.yaml`). Deployed by the auto-synced `vault-networkpolicy` Application (via `networkpolicy-appset.yaml`, wave 4).
- **lab-gateway namespace network policy** (`gitops/network/networkpolicy/`) — default-deny-all + allow-dns-and-apiserver baseline policies applied to the `lab-gateway` namespace (ADR-0016 §4 fan-out; the Gateway listener namespace). No per-workload allow rules are needed: the namespace holds only the Traefik `TLSStore` CR (ADR-0040) — no pods run in `lab-gateway` itself (Traefik itself runs in `kube-system`, bundled with k3s). Deployed by the auto-synced `lab-gateway-networkpolicy` Application (via `networkpolicy-appset.yaml`, wave 4).
- Storage backups, true HA: out of scope (single host, no in-cluster storage layer left at all). See [docs/DR.md](DR.md).
