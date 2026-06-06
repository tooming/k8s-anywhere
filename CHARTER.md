# CHARTER — k8s-lab North Star

The durable statement of **what k8s-lab is becoming**. Slow-changing. The backlog in
[ROADMAP.md](ROADMAP.md) is *derived* from this: the weekly planner computes
`(this charter) − (actual repo state) → concrete items`. Change **this** file when the
*goals* change; change ROADMAP.md when the *next steps* change.

## Mission

A localhost GitOps platform that wires the full cloud-native stack together on a single
16 GB Mac, so the pieces are learned as one coherent system — built as code end to end,
rebuildable with one command, with recovery that is *exercised*, not assumed.

## Target end-state (the platform we're growing toward)

- **Always-on core** (built): k3d + ArgoCD + GitLab + Envoy Gateway + Vault + External
  Secrets + Garage + the full LGTMP observability stack + moto/ACK/KRO + a demo app
  (~28 ArgoCD Applications).
- **Always-on next wave** (planned, ~500 MB total within budget): **Kyverno** (admission
  policy — validation, mutation, image verification); **Argo Rollouts** (SLO-driven
  canary delivery via Envoy traffic-splitting); **Velero** (cluster + PVC backup to
  Garage); **Trivy Operator** (continuous vulnerability + SBOM scanning).
- **Heavy / on-demand** (planned): a distributed database (TiDB), an artifact registry
  (Artifactory or Nexus), a service mesh + UI (Istio ambient + Kiali), and distributed
  storage (Longhorn) — each brought up *one at a time* within the 12 GB budget.
- **Capstone — the full inner loop**: GitLab CI builds *and signs* an image (cosign) →
  Kyverno verifies the signature on admit → ArgoCD deploys it → Argo Rollouts canaries it
  on real Mimir SLOs → Envoy routes it → Grafana shows its metrics & logs → Vault holds
  its secrets → Velero backs up its state.

## Learning objectives (why each piece exists)

The lab should let a learner internalize, hands-on: the **GitOps reconcile loop**; **IaC
bootstrap vs. in-cluster GitOps**; the **secrets flow** (Vault → External Secrets →
workload); **north-south ingress** via the Gateway API; the **observability pipeline**
(metrics, logs, traces, profiles); **S3-compatible storage**; **cloud control-plane
patterns** (ACK/KRO against a mock); **DR / blue-green** on a single host;
**admission-time policy** (Kyverno: validation, mutation, image verification);
**progressive delivery** (canary releases gated by real SLO metrics, not timers);
**stateful backup & restore** (Velero against Garage — restore is exercised, not
assumed); and **supply-chain security** end-to-end (cosign signing in CI, Kyverno
verifyImages on admit, continuous Trivy scanning + SBOMs). The sequenced path lives
in [docs/00-architecture.md](docs/00-architecture.md).

## Quality bars (invariants every change must keep true)

- **Everything as code; GitOps deploys it.** Workloads are ArgoCD `Application`s;
  Terraform/Terragrunt *only* bootstraps. (ADR-0001)
- **Recreate-from-code.** `make up` rebuilds the whole lab; DR is verified, not assumed
  (`make dr-verify` / `dr-test` / blue-green). (ADR-0005)
- **Stateful DR is exercised.** Every stateful namespace (`data`, `tidb`, `capstone`,
  `vault`) has a Velero schedule and a `make dr-restore` path that recovers it from the
  latest backup — not just re-creates the workload from manifest.
- **Images are signed and verified.** Every image deployed into the cluster is signed
  by the lab's cosign key in CI and admitted by a Kyverno `verifyImages` policy; an
  unsigned image is rejected at admission.
- **Clusterless gates stay green.** `make ci` (lint + validate + test + drift checks) is
  the floor and runs on every push.
- **Fits the 16 GB reality.** The always-on stack lives in the 12 GB VM (~7 GB used);
  heavy components are on-demand, never auto-synced, and never two full stacks at once.
- **Real observability only.** Dashboards and outputs reflect auto-discovered state —
  never fabricated, placeholder, or mocked data. (ADR-0004)
- **Decoupled / no needless SPOF**, and **Garage (not MinIO)** for S3. (ADR-0002, ADR-0003)
- **Docs & dashboards don't drift.** README, `docs/dependency-tree.md`, and the Grafana
  "Lab UIs" panel stay in sync (enforced by drift checks).

## How this drives the ROADMAP

The weekly **planner** routine reads this charter + the actual repo and proposes concrete
ROADMAP items for the gaps (a target not yet built, a quality bar not yet met, a learning
objective not yet covered). The every-5h **executor** routine implements one item per
run. To steer the lab, change the goals here — the roadmap, and then the work, follow.
