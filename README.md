# k8s-anywhere

*(renamed from `k8s-lab` 2026-07-13 to match the cloud-agnostic goal below)*

A **cloud-agnostic GitOps platform** that wires a small cloud-native stack together as
portable infrastructure-as-code — so you can see how the pieces actually fit, not learn
them in isolation. The identical `gitops/` state deploys to a free **localhost** cluster
(the default: one 16 GB Mac, zero external dependencies) or to any CNCF-conformant
**cloud** Kubernetes backend, chosen by swapping the Terraform/Terragrunt bootstrap
module — never by forking the GitOps layer. See
[ADR-0026](docs/decisions/adr-0026-cloud-agnostic-infrastructure.md). This repo's own
public GitHub remote holds the manifests, and **ArgoCD continuously syncs everything
else in**, identically regardless of where the cluster runs.

The sections below (Quick start, Endpoints) describe the **localhost backend**, which
is built today and remains the default. A second backend module targeting Oracle
Cloud's Always Free tier is also built and partially verified against a real account —
see [`infra/live/README.md`](infra/live/README.md) → Status for exactly what has and
hasn't run end-to-end yet.

Built as code end to end: **one command (`make up`) rebuilds the whole lab from
scratch**.

**A large simplification landed 2026-09-06/2026-09-07.** This lab used to run a much
larger stack (observability, Cilium, Garage, Forgejo, GitLab, Harbor, a DR front door +
blue/green drill, capstone, Kyverno, Argo Rollouts, Velero, Trivy Operator, Kargo, ACK,
and moto/KRO). All of it was removed entirely, no replacement, by explicit maintainer
decision — see each component's own ADR Status for why. What's documented below is the
lab's current, deliberately small shape, not a temporary gap to "finish" later.

- 📊 **[docs/dependency-tree.md](docs/dependency-tree.md)** — full dependency & integration graph (who deploys / depends on / talks to whom)
- 🛟 **[docs/DR.md](docs/DR.md)** — recovery model + the day-0 bootstrap chain
- 📐 **[docs/00-architecture.md](docs/00-architecture.md)** — roles & learning path · 🧭 **[docs/decisions/](docs/decisions/)** — ADRs

## The stack

Everything except Terraform/Terragrunt runs **in** the cluster, deployed by ArgoCD
(one `Application` per component) — 4 always-on namespaces, nothing on-demand.

| Layer | Tools |
|-------|-------|
| **Bootstrap (IaC)** | Terraform · Terragrunt · k3d (k3s-in-Docker, bundled Flannel CNI + kube-router NetworkPolicy) |
| **GitOps** | GitHub (this repo's own public remote, git source) · ArgoCD (engine, app-of-apps) |
| **Ingress** | Traefik (north-south, bundled with k3s · `IngressRoute`/`TLSStore` CRDs; ADR-0040, ADR-0016) — k3d's own load balancer publishes it directly on host `:8080`, no separate front door |
| **TLS / certificates** | cert-manager (`cert-manager-root-ca` self-signed root CA bootstrap chain — `selfsigned-bootstrap` → root `Certificate` → `k8s-lab-ca` `ClusterIssuer` · `lab-gateway-certificate` wildcard `*.127.0.0.1.nip.io` Certificate · `cert-manager-networkpolicy` default-deny overlay; ADR-0028) |
| **Demo app** | lab-demo (single static hello-world Deployment, `gitops/apps/demo/`, Docker Hub image) |

## Prerequisites

macOS with **Colima** (not Docker Desktop). Install the toolchain, then verify:

```sh
brew install colima docker k3d kubectl helm terraform terragrunt kustomize argocd yq jq mkcert
make preflight      # checks all of the above are on PATH
```

## Quick start — one command

```sh
make up             # bootstrap the ENTIRE lab from scratch, in order
make status         # VM RAM + per-namespace usage + any unhealthy pods
make dr-verify      # assert the whole lab is healthy end-to-end (real checks)
```

`make up` runs the only imperative (day-0) steps — Colima → k3d → ArgoCD → app-of-apps
— then ArgoCD reconciles everything else directly from this repo's GitHub remote. The
ordered chain is documented in [docs/DR.md](docs/DR.md). Run `make` with no target for
the full command list.

## Endpoints

After `make up`, UIs are served directly through Traefik on **`:8080`** — k3d's own
load balancer publishes it on the host, there is no separate front-door process any
more (hostnames resolve to 127.0.0.1 via `nip.io` — no `/etc/hosts` edits):

| UI | URL |
|----|-----|
| ArgoCD | http://argocd.127.0.0.1.nip.io:8080 |

`make argocd-password` prints the ArgoCD admin password.

## Disaster recovery

The lab is **recreate-from-code**. There is no automated backup/restore or
blue/green drill left (removed entirely 2026-09-07, no replacement, along with the
components they exercised) — full rebuild from git is the primary recovery
mechanism. One narrow fault-injection drill exists against a currently-live
component (added back 2026-09-11, closing a gap `docs/dora-audit-readiness.md`'s
Q12 named):

| Command | What it does |
|---------|--------------|
| `make dr-verify` | Real end-to-end health check: nodes, every ArgoCD app Synced+Healthy. Safe anytime. |
| `make dr-test` | Full DR drill: **destroy** the lab → `make up` → verify. `SCOPE=cluster\|machine`. |
| `make dr-chaos-argocd` | Fault-injection drill: kill `argocd-application-controller`, assert Kubernetes self-heals it. |

See [docs/DR.md](docs/DR.md) and [ADR-0005](docs/decisions/adr-0005-spof-recreate-over-ha.md)
(why true HA isn't possible on a single host, and what the lab does instead).

## Quality gates

`dr-verify`/`dr-test` are the *top* of the pyramid — they need a live cluster. The
*bottom* is fast, clusterless, and runs on every push via GitHub Actions (and locally):

| Command | What it checks |
|---------|----------------|
| `make lint` | `shellcheck` every script + `yamllint` the manifests/IaC |
| `make validate` | schema-validate gitops manifests (`kubeconform`) + Terraform (`fmt`/`validate`/`tflint`) |
| `make test` | `bats` unit tests: probe uptime math, destructive-script guards, the drift detectors |
| `make readme-check` · `make lab-ui-check` | docs/dashboard drift detectors |
| `make ci` | all of the above in one shot (mirrors the CI workflow) |

Tools are optional locally (skipped with a note, like `make preflight`); CI installs
them and enforces every gate.

## Layout

- `infra/` — Terraform modules + Terragrunt live config (the day-0 bootstrap)
- `gitops/` — what ArgoCD syncs: `bootstrap/` (root app-of-apps) → `platform/` (one
  `Application` per component) → `network/ apps/`
- `scripts/` — bootstrap + quality-gate scripts (`lint.sh`, `validate-*.sh`, `test.sh`)
- `tests/` — `bats` unit tests + fixtures · `.github/workflows/ci.yml` — the clusterless CI gates · `docs/` — architecture, DR, decisions, dependency tree

## Repo

`main` lives on **GitHub**
([github.com/tooming/k8s-anywhere](https://github.com/tooming/k8s-anywhere)) — this
repo's only git remote. There is no self-hosted git source any more (Forgejo and
GitLab were both removed entirely, no replacement); ArgoCD clones directly from GitHub.
