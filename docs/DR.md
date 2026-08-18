# Disaster Recovery / from-scratch bootstrap

This lab is **recreate-from-code**, not backup/restore. Everything lives in this
repo (manifests, Terraform, scripts); secrets are *generated* during bootstrap.
To rebuild the whole thing on a clean machine: `make up`.

```sh
make preflight   # check tools (brew install: colima k3d helm terragrunt kustomize argocd yq mkcert)
make up          # bootstrap everything, in order
make status      # VM RAM + per-namespace usage + unhealthy pods
```

### Cilium bootstrap order (ADR-0014)

The cluster is created with `--flannel-backend=none --disable-network-policy`
(see `infra/live/local/cluster/terragrunt.hcl`). Flannel is disabled; **Cilium
is the CNI.** Pods cannot start until Cilium is installed. On every fresh
`make cluster-up`, install Cilium **before** `make argocd`:

```sh
make cluster-up   # k3d cluster — no CNI yet; pods stay ContainerCreating
make cilium-up    # ← install Cilium first; pod networking now works
make argocd       # ArgoCD pods start; then continue with `make up` from here
# or simply re-run the full make up (it is idempotent):
make up
```

`make cilium-up` uses `helm upgrade --install` directly (day-0 seam, per ADR-0001)
and blocks until Cilium is ready. ArgoCD then adopts the Helm release on first sync.

## Velero backup restore (`make dr-restore`)

Restores every stateful namespace (`data`, `tidb`, `capstone`, `vault`,
`observability`, `inkless`) from its **latest Velero backup** and verifies
completion within the CHARTER Objective O3 budget of **< 10 minutes (600 s)**
total wall-clock.

```sh
make dr-restore   # restore all six stateful namespaces from their latest Schedule backup
```

This is distinct from `make dr-test` (which *recreates* the cluster from manifest) —
`dr-restore` proves that **data** survives: PVC contents captured by Velero/Kopia
are round-tripped back into the live namespace.

### What it does

`scripts/dr-restore.sh` iterates the six namespaces in order (sequential to avoid
disk I/O contention on the single node):

| Namespace | Schedule | Cron | TTL |
|-----------|----------|------|-----|
| `data` | `data-daily` | `0 2 * * *` | 168h |
| `tidb` | `tidb-daily` | `30 2 * * *` | 168h |
| `capstone` | `capstone-daily` | `0 3 * * *` | 168h |
| `vault` | `vault-daily` | `30 3 * * *` | 168h |
| `observability` | `observability-daily` | `0 1 * * *` | 168h |
| `inkless` | `inkless-daily` | `0 4 * * *` | 168h |

For each namespace it runs:

```sh
velero restore create dr-restore-<ns>-<ts> --from-schedule <ns>-daily --wait
```

then confirms `status.phase == Completed`. The script prints a timing table and
fails with exit code 1 if:

- any restore reaches a non-`Completed` phase (`Failed`, `PartiallyFailed`, etc.), or
- the total wall-clock across all six restores exceeds **600 s**.

### Prerequisite

Velero must be running and at least one successful backup must exist for each
Schedule. Schedules run nightly (see table above); on a fresh cluster run
`velero backup create --from-schedule <ns>-daily` to seed the first backup
manually before running `make dr-restore`.

See [ADR-0021](decisions/adr-0021-velero-backup-restore.md) for the Velero
architecture, Garage S3 backend wiring, and Objective O3 rationale.

---

## Capstone demo (`make capstone-demo`)

Runs the end-to-end capstone learning-path demo and verifies the full pipeline is
healthy within the **CHARTER Objective O6 budget of 900 s (15 min)** wall-clock.

```sh
make capstone-demo
```

### Pre-requisites

- A healthy, running lab cluster (`make up` complete, all apps Synced + Healthy).
- `argocd` CLI installed and logged in:
  ```sh
  make argocd-password    # print the admin password
  argocd login localhost:8080 --username admin --password <password> --insecure
  ```
- `kubectl` configured to the active cluster context.
- The capstone Application deployed and the `capstone.127.0.0.1.nip.io` HTTPRoute
  reachable through Envoy on port 8000.

### What it checks (four steps)

| # | Check | Tool | Budget |
|---|-------|------|--------|
| 1 | capstone ArgoCD Application is `Healthy` | `argocd app wait capstone --health` | 120 s timeout |
| 2 | capstone `ExternalSecret` status is `Ready` | `kubectl -n capstone get externalsecret` (jsonpath poll) | 30 s |
| 3 | `http://capstone.127.0.0.1.nip.io:8000/` returns HTTP 200 | `curl` | — |
| 4 | A Tempo trace exists for `service.name=capstone` (5-min look-back) | `kubectl port-forward` + Tempo `/api/search` | — |

Step 4 warns rather than hard-failing if Tempo is reachable but no trace exists yet
(traces only appear after at least one HTTP request hits the capstone endpoint). Send
a `curl http://capstone.127.0.0.1.nip.io:8000/` first if you want a trace immediately.

### Budget enforcement

`scripts/capstone-demo.sh` checks the running total after each step and prints a
summary table (elapsed per step + total) at the end. Exit code 1 if any step fails
or the total exceeds 900 s (Objective O6 requirement).

See [ADR-0020](decisions/adr-0020-argo-rollouts-progressive-delivery.md) for the
progressive-delivery context and [RFC #215](https://github.com/tooming/k8s-lab/issues/215)
for the original acceptance criteria.

---

## One-command DR test (`make dr-test`)

Proves the recreate-from-code claim end to end: it **destroys the lab, rebuilds it
with `make up`, then asserts it came back healthy** — and fails loudly if not.

```sh
make dr-test                 # default scope=full: cluster + GitLab wiped, rebuilt
make dr-test SCOPE=cluster   # faster: only the k3d cluster (GitLab + Colima survive)
make dr-test SCOPE=machine   # also delete the Colima VM (re-pulls all images)
make dr-verify               # just the health assertions (no rebuild) — safe anytime
make dr-destroy SCOPE=full   # just the teardown
```

| SCOPE | Wipes | Survives | Rebuild |
|-------|-------|----------|---------|
| `cluster` | k3d cluster (ArgoCD, Vault, Garage, all workloads, in-cluster repo secret) | GitLab + Colima | ~3-6 min. Exercises full **secret regeneration** (new Vault unseal/root keys, new Garage S3 key). The GitLab repo secret is recreated by `gitlab-configure`. |
| `full` (default) | cluster **+ GitLab container & volumes** | Colima (image cache) | ~8-15 min. The git **source** itself is rebuilt and the repo re-pushed; new GitLab token minted. |
| `machine` | full **+ the Colima VM** | nothing | ~15-30 min. Closest to a clean laptop; re-pulls every image. |

State is local + throwaway (`infra/live/local/root.hcl`), so once a layer's real
resources are gone the drill clears that layer's `terraform.tfstate` to force a
clean greenfield `make up` (cluster + ArgoCD always; GitLab on full/machine).

**What `dr-verify` checks (all live, no placeholders — see ADR-0004):**
nodes `Ready` · every ArgoCD `Application` `Synced`+`Healthy` · Vault initialized &
unsealed · all `ExternalSecret`s `SecretSynced` · Garage up with its buckets
(`mimir mimir-ruler loki tempo pyroscope`) · **Mimir actually queryable** (`up`
returns series for tenant `lab`, proving the Alloy→Mimir→Garage path) · Grafana
`/api/health` `database=ok`. Each check polls until satisfied or its budget
expires; exit 0 only if all pass.

## Zero-downtime blue/green DR (`make dr-bluegreen`)

`make dr-test` recovers the lab but has an **outage** while it rebuilds. The
blue/green drill instead recovers onto a **fresh cluster with zero downtime** —
the system keeps serving the whole time — and proves it with a live probe.

```sh
make dr-bluegreen        # stand up green alongside blue, cut over, prove ~100% uptime
make dr-bluegreen-down   # remove the green cluster + front door (blue is untouched)
```

How it works (blue = the running cluster, green = a second one):

1. **Front door** — a small nginx proxy on host **:8000** forwards to whichever
   cluster's Envoy load balancer is *active* (`scripts/bluegreen-frontdoor.sh`). It
   runs on its own port, so blue's `:8080` is **never touched**. Cutover = rewrite
   the upstream + `nginx -s reload`, which is graceful (keeps the listening socket,
   drains old workers) → **no dropped connections**.
2. **Canary** — the probe targets the **ArgoCD UI** (`argocd.127.0.0.1.nip.io`),
   which both clusters serve, so "is it up?" is a real end-to-end signal.
3. **Green** (`scripts/bluegreen-up.sh`) — a second k3d cluster `k8s-lab-green` on
   its own ports (8082/8444/6446) and docker network, with its own ArgoCD that
   syncs the **serving tier only** (`envoy-gateway`, `lab-gateway`, `demo`) from the
   *same* GitLab repo via `gitops/bluegreen/green-root.yaml` (`directory.include`).
   Two **full** LGTMP stacks don't fit 16 GB, so green recovers the always-available
   edge; the point of this drill is the **cutover**, not duplicating observability.
   (Blue+green peaks ~9.4 GB used of the 12 GB VM — fits.)
4. **Probe + cutover** (`scripts/dr-bluegreen.sh`) — start a continuous probe of
   the front door, bring green up, then repoint the front door blue→green. The
   probe records uptime across the whole drill; PASS needs **uptime ≥ 99%** and
   longest outage ≤ 2 s. Cutover is proven real two ways: the front-door config now
   targets green's load balancer, and a blue-only route (`vault.*`) starts returning
   404 through the front door (green doesn't run Vault).

The endpoint of a real blue/green is to **retire blue** — `make dr-bluegreen-promote`
does that. On 16 GB two *full* stacks can't coexist (proven: the green stack OOMs
its `alloy`/`repo-server` while blue is also full), so the order is chosen to never
overlap them: bring up a **serving-tier** green → **cut over** (zero downtime) →
**delete blue** (frees ~7 GB) → **then promote green to a full, verified stack**.
Serving never drops (a probe proved 100% — 1135/1135 — across cutover and retire);
the one unavoidable single-host tradeoff is a brief observability/Vault/Garage gap
after blue is gone until green finishes its full sync. Afterward green is the sole
environment (canonical endpoint stays `:8000`; `:8080` is gone with blue).
(`make dr-bluegreen` alone stops at cutover and keeps blue as a rollback target;
`make dr-bluegreen-down` reclaims green's RAM.) See ADR-0005.

## Chaos / fault-injection drill (`make dr-chaos`)

The drills above all test *planned* failover — you decide when the disaster
happens. This one tests an **injected** failure instead (DORA's Pillar 3 "digital
operational resilience testing" — the TLPT, threat-led penetration testing,
concept): it kills a running capstone pod at a moment you don't control the
timing of, then asserts the cluster self-heals within budget.

```sh
make dr-chaos   # kill a random capstone pod, assert a replacement reaches Running within 120s
```

What it does: pick one running capstone pod at random (`scripts/dr-chaos.sh`,
bash `$RANDOM`, no external random-picker dependency), delete it, then poll until
a genuinely new, Ready replacement pod count is back to its pre-injection value
or the budget is exceeded — the poll explicitly excludes the deleted pod's own
name and checks actual container readiness, not just pod phase (fixed 2026-08-13:
a pod stays `phase=Running` throughout its termination grace period, so an
earlier version of this check could count the pod being deleted as still
"healthy" and report a false-positive instant pass). The
capstone Rollout runs a **single replica** (no HA — ADR-0005), so this is an
honest test of *recreate*, not of masking an outage behind a spare replica: there
*is* a brief gap while Kubernetes reschedules. The 120 s budget is 4x the ~30 s a
healthy node normally takes to reschedule + restart a pod whose image is already
cached (the pod we killed was already running it, so no cold image pull is
needed) — generous enough to absorb a slow node without masking a real
regression.

This introduces no new failure mode: pod-delete-then-recreate is a guarantee
Kubernetes' ReplicaSet controller (which the Rollout manages) already provides.
The drill only *observes and times* that existing guarantee — its only
real-world side effect is one capstone pod restarting, the same event a node
drain or an OOM-kill would already cause routinely.

## Network-partition drill (`make dr-network-partition`)

A second, distinct injected-failure scenario (same DORA Pillar 3 / TLPT concept
as `dr-chaos` above) — `docs/dora-audit-readiness.md` Q12 named this as a real,
separately-scoped follow-up once the pod-kill drill existed: "cutting a
NetworkPolicy... still real, separately-scoped future drills if wanted." Where
`dr-chaos` tests Kubernetes' own ReplicaSet/Rollout self-heal, this one tests
**ArgoCD's** self-heal — a different recovery mechanism, a different failure
domain.

```sh
make dr-network-partition   # delete capstone's ingress NetworkPolicy, assert ArgoCD restores it within 300s
```

What it does: deletes the `allow-capstone-ingress-from-gateway` NetworkPolicy
live in the `capstone` namespace (`scripts/dr-network-partition.sh`) — since
capstone's default-deny floor (ADR-0016) then has no matching allow left,
every Envoy-Gateway-routed request to the app is dropped for the duration of
the drill — then polls until the object reappears (ArgoCD's `selfHeal: true`
on `gitops/platform/networkpolicy-appset.yaml`'s `syncPolicy.automated`
reconciling the live drift back to git's declared state) or the 300 s budget
is exceeded.

This introduces no new failure mode: ArgoCD re-applying a manifest that
drifted from git is the same guarantee `selfHeal: true` already provides for
*any* live edit or deletion under its management, accidental or otherwise.
The drill only *observes and times* that existing guarantee — its only
real-world side effect is capstone's ingress route being briefly unreachable,
the same outcome a maintainer's own `kubectl delete` typo would already cause.

## Garage-failure drill (`make dr-garage-failure`)

A third, distinct injected-failure scenario (same DORA Pillar 3 / TLPT concept
as the two drills above) — `docs/dora-audit-readiness.md` Q12 named this as
the last of its own follow-ups once the pod-kill and NetworkPolicy-delete
drills existed: "Simulating Garage unavailability... a different failure
domain (storage-layer availability)." Where `dr-chaos` and
`dr-network-partition` both exercise capstone's recovery paths, this one
targets Garage (`gitops/storage/garage/statefulset.yaml`, the lab's
S3-compatible storage backend, ADR-0002) — the same Kubernetes
ReplicaSet/StatefulSet self-heal mechanism `dr-chaos` proves out, just for a
previously-uncovered component.

```sh
make dr-garage-failure   # kill the single-replica Garage pod, assert Kubernetes restores it within 120s
```

What it does: deletes the single running Garage pod live in the `storage`
namespace (`scripts/dr-garage-failure.sh`) — Garage runs as a single-replica
`StatefulSet` (no HA, per ADR-0005 — recreate over pretend-HA on one host),
so this briefly interrupts S3 API availability for any in-flight request —
then polls until a replacement pod's container reports ready (excluding the
deleted pod's own name, the same self-heal-detection fix `dr-chaos.sh`'s own
self-review found and fixed, reused here rather than reintroduced) or the
120 s budget is exceeded.

This introduces no new failure mode: pod-delete-then-recreate is a guarantee
Kubernetes already provides for any StatefulSet-managed pod. The drill only
*observes and times* that existing guarantee. Not covered by this drill: a
multi-pod/quorum-loss scenario (not applicable — Garage runs single-replica
in this lab) or a full node-loss scenario, both real, separately-scoped
future gaps if ever worth closing.

## Results history log ([`docs/dr-results-log.md`](dr-results-log.md))

Each of the six drills above (`dr-restore`, `dr-bluegreen`, `dr-chaos`,
`dr-network-partition`, `dr-garage-failure`, `capstone-demo`) appends one row — date, status (`PASS`/`FAIL`), elapsed
seconds, budget seconds, objective tag — to
[`docs/dr-results-log.md`](dr-results-log.md) on **every** run, pass or fail
(`scripts/lib/dr-results-log.sh`'s `dr_log_result`, called from each script's
exit path). This closes the gap `docs/dora-audit-readiness.md` Q13 named:
pass/fail was already enforced by exit codes, but there was no historical
trend — no way to see if, say, the restore is creeping toward its 600 s
budget as the lab grows, only whether today's run passed. The log is
append-only and never hand-edited or backfilled (ADR-0004) — it ships with
just the header until a real run happens.

## Single points of failure (and why true HA isn't possible here)

Once you cut over to green and retire blue, two SPOFs remain — in **different paths**:

| SPOF | Path | If it fails | Blast radius |
|------|------|-------------|--------------|
| **Front load balancer** (nginx `:8000`) | **Serving** | the stable endpoint is down until it restarts | the whole site, briefly |
| **GitLab** (omnibus container) | **Control / recovery** | running workloads keep serving (ArgoCD holds last-synced state); but you can't sync changes or **recover** | no serving impact; recovery is blocked |

**The hard truth: you cannot make this HA on a single machine.** HA needs ≥2
independent failure domains; here the Colima VM (and the laptop) is itself the
ultimate SPOF. Running two nginx front doors or two GitLabs on the same host removes
nothing — they share the one thing that actually fails. So the honest lab goals are
**resilience** (self-heal, fast restart) and **recoverability** (recreate-from-code),
not true HA. What that looks like, and how you'd really do it in production:

### Front load balancer
- **Lab today:** the front door runs with `--restart unless-stopped`, so Docker
  restarts it within ~1 s of a crash. That's *resilience*, not HA — a crash is still
  a sub-second blip, and a host failure takes it down with everything else.
- **Production HA:** the front LB is never a single box. Either a managed cloud LB
  (multi-AZ, the cloud owns its redundancy), or a self-managed pair (HAProxy/nginx ×2)
  sharing a **virtual IP via keepalived/VRRP**, fronted by **DNS** with health checks.
  The VIP fails over between LBs in ~seconds; DNS spreads across regions. The point:
  N≥2 LBs across N≥2 hosts/AZs, with an automatic failover mechanism.

### GitLab (the DR irony)
GitLab is the source of truth for a system whose *recovery* is GitOps — so a single
GitLab means a single point of failure **in the recovery path itself**. Note it does
*not* take serving down: if GitLab dies, every running workload keeps running on
ArgoCD's last-synced state; only new syncs/recovery pause.
- **Lab today:** GitLab is **recreate-from-code** — its data lives in the local clone
  and both clusters' ArgoCD repo caches, and `make dr-test SCOPE=full` proves it
  rebuilds and re-pushes from the local clone in ~5 min (RTO, not HA).
- **Production HA:** GitLab Geo / a multi-replica HA topology (Postgres + Gitaly
  Cluster + object storage), which is far too heavy for 16 GB. The lighter, lab-shaped
  step toward removing the *recovery* SPOF is a **git mirror**: push-mirror the repo to
  a second remote and let ArgoCD **fail over** its `repoURL` when GitLab is unreachable.
  (Designed, not built — see the SPOF decision in `docs/decisions/`.)

## The order (what `make up` does, and why)

The only **imperative** steps are the day-0 seam (you can't GitOps the GitOps
engine or its git source into existence). Everything after the root app-of-apps
is reconciled by ArgoCD from GitLab.

| # | Step | `make` target | Imperative? | Why this order |
|---|------|---------------|-------------|----------------|
| 1 | Colima VM | `colima-up` | yes | container runtime |
| 2 | Terraform-state Garage | `tfstate-up` | yes (docker compose + `scripts/tfstate-bootstrap.sh`) | off-cluster S3 backend for Terraform state (ADR-0007); must precede any `terragrunt apply`, so before the cluster itself |
| 3 | k3d cluster | `cluster-up` | yes (Terraform) | the substrate — created with **no CNI** (`--flannel-backend=none`, ADR-0014) |
| 4 | Cilium CNI | `cilium-up` | yes (Helm) | the CNI — nodes stay `NotReady` and pods can't schedule until this runs; must precede ArgoCD (ADR-0014) |
| 5 | CoreDNS host alias | `coredns-host-alias` | yes (`scripts/coredns-host-alias.sh`) | teaches CoreDNS to resolve `host.k3d.internal` (k3d 5.x on Colima omits this); needed before ArgoCD's `repoURL` (which targets `host.k3d.internal`) can resolve |
| 6 | ArgoCD | `argocd` | yes (Terraform/Helm) | the GitOps engine — must exist before GitOps |
| 7 | GitLab omnibus | `gitlab-up` | yes (docker) | the git **source** — can't be created by ArgoCD (chicken-and-egg, ADR-0001) |
| 8 | GitLab project + repo secret + push | `gitlab-configure` | yes (Terraform + git) | mints root token (`scripts/gitlab-pat.sh`), creates the project + ArgoCD repo deploy-token, pushes the repo |
| 9 | App-of-apps | `root-app` | yes (`kubectl apply`) | the single seed; ArgoCD now syncs **everything else** |
| 10 | Vault bootstrap | `vault-bootstrap` | yes (`scripts/vault-bootstrap.sh`) | init/unseal, store keys in `vault-keys`, enable KV, **generate+write secrets**, enable k8s auth + `eso` role |
| 11 | GitLab TLS bootstrap | `gitlab-tls-bootstrap` | yes (`scripts/gitlab-tls-bootstrap.sh`) | mint mkcert cert + start nginx TLS proxy + publish `gitlab-tls-ca` ConfigMap; must run after Vault (the observability namespace is created by ArgoCD by this point) and before Garage, so the CA is in place before Grafana's init container bakes its CA bundle |
| 12 | Garage bootstrap | `garage-bootstrap` | yes (`scripts/garage-bootstrap.sh`) | assign layout, create S3 key + buckets, push the S3 key to Vault |
| 13 | Cosign bootstrap | `cosign-bootstrap` | yes (`scripts/cosign-bootstrap.sh`) | generate the cosign keypair + seed the `cosign-public-key` ConfigMap in `kyverno` (idempotent, ADR-0019); needs Garage's S3 key in place first |
| 14 | Front door | `frontdoor` | yes (`scripts/frontdoor-ensure.sh`) | bring up the stable `:8000` entry point to the active cluster (canonical lab entry) |
| 15 | Grafana Git Sync bootstrap | `grafana-gitsync-bootstrap` | yes (`scripts/grafana-gitsync-bootstrap.sh`) | create the Pure Git `Repository` in Grafana's unified storage + set the home dashboard; must run once Grafana is healthy (waits up to 5 min) |

Once 9–10 are done, **External Secrets** syncs Vault → k8s Secrets, and the
workloads (Garage, Mimir, Grafana, Alloy, Envoy, moto, …) come up on their own.

### Secret dependency chain (subtle bit)
- Vault must hold `secret/garage/server` **before** Garage starts (ESO → `garage-secrets` → Garage). `vault-bootstrap` generates it.
- Garage's S3 access key is created **after** Garage is up, then pushed to Vault (`secret/garage/s3`) → ESO → `garage-s3` → Mimir. `garage-bootstrap` does this.

## Golden rules (keep it acyclic — ADR-0001)
- **Never** source ArgoCD's git credentials or Vault's unseal key *from Vault*
  (that creates an ArgoCD↔Vault cycle). The repo secret is Terraform-made; the
  unseal key lives in the `vault-keys` k8s Secret.
- ESO/Vault being down does **not** kill running workloads — their k8s Secrets
  persist; only refresh/new-secret creation pauses.

## What is NOT preserved on a rebuild
Recreate model → fresh everything: new Vault root/unseal keys, new Garage S3 key,
empty metrics history. That's expected for a throwaway lab. If you ever want true
data survival across a *cluster* rebuild, that's a separate exercise (external
backups; not in scope).

## Recovery cookbook (single-component)
- **Vault sealed** (after a pod restart): the in-cluster `vault-unsealer` re-unseals
  automatically within ~10s. Manual: `make vault-unseal`.
- **GitLab down / freeing RAM:** `make gitlab-down` (keeps volumes), `make gitlab-up` to bring back.
- **ArgoCD out of sync after a git push:** `kubectl -n argocd annotate applications.argoproj.io/root argocd.argoproj.io/refresh=hard --overwrite`.
- **Re-run a bootstrap safely:** `vault-bootstrap` and `garage-bootstrap` are idempotent.
- **Grafana Git Sync dashboards missing after a cluster rebuild or Grafana pod restart:**
  run `make gitlab-tls-bootstrap` (re-publishes the mkcert CA ConfigMap and restarts
  Grafana if needed), then `make grafana-gitsync-bootstrap` (re-creates the Repository in
  unified storage). Both are idempotent. After `make up` these steps are automatic.

### k3s embedded datastore (SQLite/kine) health

**2026-08-11 incident** (see `docs/incident-log.md`): after 25 days of continuous
uptime on `k3d-k8s-lab-server-0`, `docker logs` showed "Slow SQL" warnings for basic
kine-table queries (`SELECT MAX(id)`, `compact_rev_key` lookups) taking **1-48
seconds** instead of sub-millisecond, alongside apiserver TLS handshake timeouts,
`FinishRequest ... context deadline exceeded`, and `apiserver was unable to write a
JSON response: http: Handler timeout` — genuine control-plane-wide degradation, not
pod-level churn. `kubectl get nodes` itself failed with a TLS handshake timeout while
this was happening.

**Root cause, confirmed live:** k3s's kine layer runs a background compactor roughly
every 5 minutes (visible as `"COMPACT compacted from X to Y"` log lines). On this node
it went **completely silent — zero COMPACT lines, success or failure — for 16 straight
days** after a burst of `"Compact failed: failed to record compact revision: sql:
transaction has already been committed or rolled back"` errors on 2026-07-25.
`state.db` had grown to 505MB with an 82MB uncheckpointed WAL. Notably, an earlier k3s
server restart that same day had only bought ~6 hours of healthy compaction before the
compactor silently died again — **a restart is not a durable fix by itself**, only a
way to buy time until the same failure mode recurs. Sustained resource-reconciliation
churn (Kyverno's own multi-day restart-loop history, dozens of continuously-reconciling
ArgoCD Applications) is the plausible write-pressure driver, but the proximate cause is
the compactor thread dying and never restarting itself, not datastore size in isolation.

**Detect it:** `make k3s-datastore-health-check` (also runs as an informational,
non-blocking section of `make health`) — checks `state.db`/WAL size, the gap since the
last successful compaction, and recent "Slow SQL" warning volume, entirely via `docker
logs`/`docker exec` against the k3d container (no `kubectl` — the whole point is to
still work when the apiserver itself is the thing timing out).

**Recover it, cheapest/lowest-risk first:**
1. **Restart the k3s server container** (`docker restart k3d-k8s-lab-server-0`) — cheap,
   resumes the compactor immediately, no data loss. **Not durable on its own** per the
   incident above; re-run the health check afterward and periodically, don't assume one
   restart is the end of it.
2. **If it recurs quickly:** stop k3s, `sqlite3 state.db 'VACUUM;'` to reclaim bloat the
   incremental compactor already left behind (VACUUM needs k3s stopped — it takes an
   exclusive lock), then restart. Higher risk (direct file-level surgery on the
   datastore) — treat as a deliberate interactive-session action, verify a backup/
   snapshot posture first, never something an autonomous routine does unprompted per
   ADR-0004.
3. **Last resort — recreate the cluster:** `make down && make up` gives a fresh
   `state.db` outright. This is the lab's standing recreate-from-code answer (ADR-0005)
   and is always safe to reach for, but it's whole-cluster, not targeted, and workload
   state not covered by Velero (`make dr-restore`) is lost — prefer options 1-2 first.

No k3s flag exists to *tune* the sqlite/kine compaction interval or force a manual
compaction (unlike embedded etcd, which exposes `--etcd-arg`); the interval is
internal to kine and not currently k3s-CLI-configurable. The mechanical guard here is
therefore detection (the health check above), not prevention — there is no dial to turn
that would structurally rule this class of failure out.

**A restart's symptom relief is not proof the compactor thread itself resumed.**
Confirmed 2026-08-17 (second real occurrence of this incident, `docs/incident-log.md`):
apiserver responsiveness and cluster-wide pod health recovered within minutes of
`docker restart k3d-k8s-lab-server-0`, but no fresh `"COMPACT compacted from X to Y"`
line appeared in the 20 minutes that followed — the restart clears the immediate
symptom (flushes the WAL, restores query latency) without necessarily restarting the
compactor goroutine itself. Re-run `make k3s-datastore-health-check` a while after any
restart, not just immediately after, before trusting the incident is actually closed.

### Harbor signed-image-pipeline verification (issues #631 / #633)

**Why this exists:** since 2026-07-20, standing issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) (confirm a CI run pushes a
cosign-signed image to Harbor) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (confirm a Kargo canary
promotion completes end-to-end) have had roughly a dozen live-cluster session
attempts. Every attempt found and durably fixed a real, distinct bug — but none has
yet completed one full pipeline run start to finish, because the *next* live session
kept re-discovering the prior fixes from scratch by re-reading issue-comment history.
This entry exists so that stops here: read this once, don't re-derive it.

**Already fixed and durably in git (do NOT re-diagnose these — verify they're still
applied, then move past them):**
1. Cilium apiserver-connectivity drift after a k3d node IP reshuffle — fixed live via
   `make cilium-up` (2026-07-29, non-persistent; re-check if it recurs).
2. `artifactory` namespace's default-deny NetworkPolicy had no intra-namespace allow
   (PR #884, 2026-07-29) — superseded by the Harbor cutover, kept for history.
3. `envoy-gateway-system`'s egress NetworkPolicy never allowlisted the `harbor`
   namespace (PR #968, 2026-08-04) — every Envoy→Harbor request timed out until this
   merged.
4. Stale Harbor admin credentials in Vault (`secret/harbor/registry`) and the GitLab
   `HARBOR_USER`/`HARBOR_PASSWORD` CI variables — fixed live 2026-08-04 (not
   GitOps-managed, no PR; re-verify these are still correct if `docker login` fails
   again).
5. No GitLab Runner was ever registered against this lab's GitLab instance, so no
   pipeline had ever executed at all (PR #1026, 2026-08-04/05).
6. `k3d-k8s-lab-server-0` node disk pressure caused Harbor pods to crashloop — found
   2026-08-05 (root cause: a stopped-but-not-deleted DR green cluster,
   `k8s-lab-green`, holding ~10GB of container volumes), fixed live 2026-08-06
   (`k3d cluster delete k8s-lab-green`), and **confirmed resolved 2026-08-10**
   (`DiskPressure: False`, 74% usage, issue
   [#1034](https://github.com/tooming/k8s-anywhere/issues/1034) closed). Worth a
   quick `df -h`/`kubectl describe node` sanity check given time has passed since,
   but this is not a standing blocker.
7. Vault sealed for 9+ hours, silently breaking ExternalSecrets cluster-wide,
   including Harbor's (PR #1038, 2026-08-06).
8. Harbor chart's default 1-second probe timeouts self-inflicted crashloops under
   real host load — bumped to 5s (PR #1040, 2026-08-06).
9. `allow-harbor-ingress.yaml`'s NetworkPolicy listed the Harbor **Service** port
   (`80`) instead of the destination **pod's** real `containerPort` (`8080`) —
   NetworkPolicy `ports:` always match the pod's port, never the Service's; this
   silently blocked every cross-namespace request to Harbor for as long as the policy
   existed (PR #1054, 2026-08-07).
10. The `capstone-pipeline` namespace was stuck `Terminating` for 20 days — a
    chicken-and-egg deadlock where Kargo's own controller (needed to clear the
    finalizer) wasn't running because the `kargo` on-demand unit was down — fixed
    live by bringing `kargo`'s controller stack up (2026-08-07, structural, no PR).
11. Kargo 1.11.0's admission webhook rejects a `Warehouse` with
    `imageSelectionStrategy: Digest` and no `constraint` field — added
    `constraint: latest` (PR #1055, 2026-08-07).
12. In-cluster pulls of `harbor.127.0.0.1.nip.io` resolved to the pulling pod's own
    loopback, not Harbor's real Service (`nip.io` is host-only DNS) — fixed with a k3d
    containerd registry mirror (`docs/done/2026-08-07-k3d-registry-mirror-harbor.md`,
    ROADMAP item already checked off).
13. `gitops/platform/harbor.yaml` used `registry.registry.extraEnvVarsSecret`, a field
    that doesn't exist in the `goharbor/harbor` chart — Harbor's registry component
    never actually received its S3 credentials, so every push failed with
    `s3aws: NoCredentialProviders` (PR #1114, 2026-08-11). Switched to the chart's real
    `extraEnvVars`/`valueFrom.secretKeyRef` mechanism.
14. Kyverno's admission-controller webhook was crashlooping on a too-tight
    chart-default startup-probe timeout, intermittently blocking ArgoCD from applying
    the fix above (PR #1115, 2026-08-11).

**What's genuinely still needed — not a code fix, a live verification window:** every
fix above is durable and in git. What has never yet happened is one session with
*sustained* host headroom to keep Harbor's full stack (7 components + Postgres)
stable through a complete `docker login && push && cosign sign` cycle without the
host's load average climbing past 100 mid-attempt. Per the accumulated findings
across every attempt above:
1. Disk pressure (issue #1034) is already confirmed resolved as of 2026-08-10 — a
   quick `df -h`/`DiskPressure` sanity check is still worth doing given time has
   passed, but this is no longer a standing gate to check first.
2. Bring up Harbor **alone** — no Kargo, no other on-demand component running
   concurrently — and give it a few minutes to fully stabilize before triggering
   anything. Every prior attempt that hit a host-capacity ceiling did so with Harbor
   and at least one other heavy on-demand unit running together.
3. Trigger a pipeline run, confirm `sign-image` completes, and verify a
   `<digest>.sig` tag lands in Harbor's `library/hello` repository. Comment the result
   on #631.
4. Only then bring `kargo` up against the now-signed image and watch for a Warehouse
   discovery → Freight → Promotion cycle to complete. Comment the result on #633.
5. Once both are confirmed, the ROADMAP items gated on these issues
   (`verifyImages` Enforce-flip, the O4 CI rejection-gate job, and capstone
   `Deployment` removal) unblock in the same session or the next executor run.

For severity triage when something breaks, see [`docs/incident-log.md`](incident-log.md)'s
severity scheme (P0–P3) and its log of real incidents this lab has actually hit.

See [decisions/](decisions/) for the rationale behind these choices.
