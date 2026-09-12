# Disaster Recovery / from-scratch bootstrap

This lab is **recreate-from-code**, not backup/restore. Everything lives in this
repo (manifests, Terraform, scripts); secrets are *generated* during bootstrap.
To rebuild the whole thing on a clean machine: `make up`.

```sh
make preflight   # check tools (brew install: colima docker k3d kubectl helm terraform terragrunt kustomize argocd yq jq mkcert)
make up          # bootstrap everything, in order
make status      # VM RAM + per-namespace usage + unhealthy pods
```

**Honest scope, as of 2026-09-07.** This lab went through a large, deliberate
simplification the same day: Velero (backup/restore), Garage (its S3 target), the
DR front door, capstone, and the chaos/network-partition/storage-failure/blue-green
drills that all depended on them were removed entirely, no replacement. There is
**no automated backup/restore and no zero-downtime cutover drill left in this
lab** — full-cluster-recreate-from-git (`make down && make up`) is the primary
recovery mechanism. This is a plain statement of current fact (ADR-0004), not a gap
to silently paper over: the maintainer's explicit direction this session was
aggressive simplification, and a lab this small has no stateful data left worth a
dedicated backup mechanism (see each removed component's own ADR Status for the
reasoning). One narrow fault-injection drill was added back 2026-09-11
(`make dr-chaos-argocd`, below) against a currently-live always-on component — it
is not a general replacement for the removed drills, and not an adversarial/
penetration-style test (DORA's TLPT concept, see `docs/dora-audit-readiness.md`
Q12).

## What `make up` does, and why

The only **imperative** steps are the day-0 seam (you can't GitOps the GitOps
engine into existence). Everything after the root app-of-apps is reconciled by
ArgoCD from GitHub.

| # | Step | `make` target | Why this order |
|---|------|---------------|-----------------|
| 1 | Colima VM | `colima-up` | container runtime |
| 2 | k3d cluster | `cluster-up` | the substrate — ships with Flannel (CNI) + kube-router (NetworkPolicy) bundled and enabled, no separate CNI install step |
| 3 | ArgoCD | `argocd` | the GitOps engine — must exist before GitOps |
| 4 | App-of-apps | `root-app` | the single seed; ArgoCD now syncs everything else, directly from this repo's public GitHub remote |
| 5 | CoreDNS nip.io rewrite | `coredns-nip-io-rewrite` | teaches CoreDNS to resolve every `*.127.0.0.1.nip.io` lab hostname to Traefik's in-cluster Service |

(A step teaching CoreDNS to resolve `host.k3d.internal` used to run here, between
steps 2 and 3 — load-bearing only for ArgoCD's old local-Forgejo `repoURL`. Removed
2026-09-09 after live verification (issue #1517) that `argocd`/`root-app` succeed
against the current public GitHub `repoURL` without it; k3d itself now also injects
`host.k3d.internal` into CoreDNS natively on cluster create, so even a future
consumer wouldn't need this repo's help for that hostname.)

Once step 4 is done, the remaining workloads (Traefik, cert-manager, lab-demo)
come up on their own — no secrets-bootstrap step left to run (Vault and External
Secrets Operator were removed entirely 2026-09-07, ADR-0042, no replacement; no
credential currently flowing through the lab needs an external secrets store).

### Golden rules (keep it acyclic — ADR-0001)
- **Never** source ArgoCD's git credentials from anywhere but Terraform's own
  bootstrap — no in-cluster component should hold the keys to its own reconciler.

### What is NOT preserved on a rebuild
Recreate model → fresh everything. That's expected for a throwaway lab — there is
no stateful application data left in this lab to lose (see the honest-scope note
above).

**A bare `colima delete` is not a clean slate.** `make down`/`colima stop` is the
normal stop/start cycle — Colima's container-runtime data (including the k3s
embedded datastore) is correctly kept, matching `make down`'s own doc comment
("Data on PVCs/volumes is kept"). But `colima delete` alone tears down only the
Lima VM itself; it **deliberately preserves** that same container-runtime data
across VM recreation, so a `make up` afterward silently resumes from the old
state rather than a genuine fresh boot. This was found live 2026-09-06
([`docs/incident-log.md`](incident-log.md)'s k3s-datastore-persistence entry): a
90MB `state.db` immediately after a supposedly-fresh bootstrap (a real fresh k3s
datastore is single-digit MB) turned out to be hours old, because the prior
`colima delete` never actually wiped the container-runtime data. **To genuinely
start over**, use `colima delete --data` (or `colima delete -f --data` to skip
the confirmation prompt) — the flag that actually wipes it — not a bare
`colima delete`.

## `make dr-test`, `make dr-verify`, `make dr-destroy`

The only DR mechanism this lab still has: prove the recreate-from-code claim end
to end.

```sh
make dr-test                 # default scope=cluster: destroy + rebuild with `make up`, then verify
make dr-test SCOPE=machine   # also delete the Colima VM (re-pulls all images)
make dr-verify               # just the health assertions (no rebuild) — safe anytime
make dr-destroy SCOPE=cluster # just the teardown
```

A third scope, `full` (also wiping the self-hosted Forgejo git remote), existed
until 2026-09-07 — Forgejo was removed entirely that day, no replacement (the repo
now lives only on its public GitHub remote, which a local DR drill neither destroys
nor rebuilds), so it collapsed into `cluster` and was dropped.

`dr-verify` checks (all live, no placeholders — see ADR-0004): nodes `Ready`,
every ArgoCD `Application` `Synced`+`Healthy`. Each check polls until satisfied or
its budget expires; exit 0 only if all pass.

## `make dr-chaos-argocd` — fault-injection drill

```sh
make dr-chaos-argocd   # kills the live argocd-application-controller pod, asserts self-heal
```

Closes the real gap `docs/dora-audit-readiness.md`'s Q12 named verbatim: the three
fault-injection drills this lab used to run (`dr-chaos`, `dr-network-partition`,
`dr-garage-failure`) each targeted a component removed entirely 2026-09-07
(capstone, Garage) and were deleted with no replacement written against any
currently-live component. This is that replacement, narrowly scoped to one
concrete instance: it deletes the live `argocd-application-controller` pod (same
type-to-confirm gate as `dr-test`/`dr-destroy` — `DR_ASSUME_YES=1` bypasses it for
scripted use), then polls for Kubernetes' own StatefulSet controller to recreate
and re-ready a new pod (a different UID), then polls for every ArgoCD `Application`
to return to `Synced`+`Healthy` (the same predicate `dr-verify` uses). Exit 0 only
if both recover within budget (`DR_T_POD`/`DR_T_ARGO` seconds, defaults 120/300).

**Honest scope.** This is one narrow instance against one always-on, single-replica
component — not a general chaos-engineering harness, not an adversarial/
penetration-style test (DORA's TLPT concept), and not a claim of regulatory
compliance (see CHARTER.md's Goals section on this lab's educational-only DORA
framing). Requires a live cluster — never runs in CI; `make ci` only lints this
script and exercises its non-destructive confirmation-guard path
(`tests/dr-guards.bats`).

## `make dr-chaos-cert-manager` — fault-injection drill

```sh
make dr-chaos-cert-manager   # kills the live cert-manager controller pod, asserts self-heal
```

The second of three follow-ups to `dr-chaos-argocd` narrowing
`docs/dora-audit-readiness.md`'s Q12 gap further (Traefik and `lab-demo` are
separate drills). Deletes the live cert-manager controller pod (selector
`app.kubernetes.io/name=cert-manager` — same type-to-confirm gate as
`dr-chaos-argocd`), then polls for Kubernetes' own Deployment controller to
recreate and re-ready a new pod (a different UID), then polls for the
root-CA issuer chain (`gitops/cert-manager/root-ca/`) — the `k8s-lab-ca`
`ClusterIssuer` and the `k8s-lab-root-ca` `Certificate` — to report `Ready`
again. Exit 0 only if all three recover within budget (`DR_T_POD`/
`DR_T_ISSUER` seconds, defaults 120/300).

**Honest scope.** Same narrow, single-instance shape as `dr-chaos-argocd`
above — not a chaos-engineering harness, not a TLPT-style test. The
controller-pod selector is the upstream Jetstack chart's own documented
label but **has not been confirmed against a real running cluster from this
clusterless authoring session** (ADR-0004) — verify it on the next live
cluster rebuild before trusting this drill's pass/fail result. Requires a
live cluster — never runs in CI; `make ci` only lints this script and
exercises its non-destructive confirmation-guard path (`tests/dr-guards.bats`).

## `make dr-chaos-traefik` — fault-injection drill

```sh
make dr-chaos-traefik   # kills the live Traefik pod, asserts self-heal
```

The third and last of the three follow-ups to `dr-chaos-argocd` narrowing
`docs/dora-audit-readiness.md`'s Q12 gap further — after this and
`dr-chaos-cert-manager` above, `dr-chaos-lab-demo` is the only remaining
always-on component without a drill. Deletes the live Traefik pod
(selector `app.kubernetes.io/name=traefik`, `kube-system` namespace — the
same selector this repo's own
`gitops/argocd/networkpolicy/allow-argocd-server-from-gateway.yaml` already
uses to reach the same pod, not a new assumption), then polls for
Kubernetes' own Deployment controller to recreate and re-ready a new pod (a
different UID), then polls the lab's own HTTP front door
(`http://argocd.127.0.0.1.nip.io:8080/healthz` — the identical URL
`lab-health-check.sh`'s own `UI_PROBES` already probes) until it answers
again. Exit 0 only if both recover within budget (`DR_T_POD`/`DR_T_HTTP`
seconds, defaults 120/180).

**Honest scope.** Same narrow, single-instance shape as `dr-chaos-argocd`
and `dr-chaos-cert-manager` above — not a chaos-engineering harness, not a
TLPT-style test. Killing the lab's only ingress path means every other
always-on UI briefly returns errors too, same as a real Traefik outage
would — this drill measures how fast that outage self-heals, not whether it
happens (ADR-0005: a single-host lab has this SPOF by design, see "Single
points of failure" below). Requires a live cluster — never runs in CI;
`make ci` only lints this script and exercises its non-destructive
confirmation-guard path (`tests/dr-guards.bats`).

## `make dr-chaos-lab-demo` — fault-injection drill

```sh
make dr-chaos-lab-demo   # kills the live lab-demo (hello) pod, asserts self-heal
```

The fourth and last of the four fault-injection drills narrowing
`docs/dora-audit-readiness.md`'s Q12 gap — after this, every one of the
lab's four always-on components (ArgoCD, cert-manager, Traefik, `lab-demo`)
has a drill. Deletes the live `hello` pod (selector `app: hello`,
`lab-demo` namespace), then polls for Kubernetes' own Deployment
controller to recreate and re-ready a new pod (a different UID). Its
recovery predicate differs from the other three: `lab-demo` has no
`Service` or `IngressRoute` (confirmed directly — no `Service` manifest
exists under `gitops/apps/demo/`, and `deployment.yaml`'s own header
comment says so explicitly), so there's no HTTP front-door URL to probe.
Instead it `kubectl exec`s into the new pod and `cat`s the
ConfigMap-mounted `index.html` directly, confirming it still serves the
real `lab-demo-hello` content — a stronger check than pod-`Ready` alone,
since it also confirms the `ConfigMap` volume actually re-attached. Exit 0
only if both recover within budget (`DR_T_POD`/`DR_T_CONTENT` seconds,
defaults 120/60).

**Honest scope.** Same narrow, single-instance shape as the three drills
above — not a chaos-engineering harness, not a TLPT-style test. Requires a
live cluster — never runs in CI; `make ci` only lints this script and
exercises its non-destructive confirmation-guard path
(`tests/dr-guards.bats`).

## Single points of failure (and why true HA isn't possible here)

| SPOF | Path | If it fails | Blast radius |
|------|------|-------------|--------------|
| **Traefik / k3d load balancer** (`:8080`) | Serving | the only entry point is down until it restarts | the whole site, briefly |
| **GitHub** (this repo's own remote) | Control / recovery | running workloads keep serving (ArgoCD holds last-synced state); but you can't sync changes or recover | no serving impact; recovery is blocked |
| **Colima VM / the laptop itself** | Everything | total outage | the whole lab |

**The hard truth: you cannot make this HA on a single machine.** HA needs ≥2
independent failure domains; here the Colima VM (and the laptop) is itself the
ultimate SPOF. So the honest lab goals are **resilience** (self-heal, fast
restart) and **recoverability** (recreate-from-code), not true HA — see
[ADR-0005](decisions/adr-0005-spof-recreate-over-ha.md).

## Recovery cookbook (single-component)
- **ArgoCD out of sync after a git push:** `kubectl -n argocd annotate applications.argoproj.io/root argocd.argoproj.io/refresh=hard --overwrite`.

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
way to buy time until the same failure mode recurs.

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
   and is always safe to reach for, since there is no workload state left to lose.

No k3s flag exists to *tune* the sqlite/kine compaction interval or force a manual
compaction (unlike embedded etcd, which exposes `--etcd-arg`); the interval is
internal to kine and not currently k3s-CLI-configurable. The mechanical guard here is
therefore detection (the health check above), not prevention.

**A restart's symptom relief is not proof the compactor thread itself resumed.**
Confirmed 2026-08-17 (second real occurrence of this incident, `docs/incident-log.md`):
apiserver responsiveness and cluster-wide pod health recovered within minutes of
`docker restart k3d-k8s-lab-server-0`, but no fresh `"COMPACT compacted from X to Y"`
line appeared in the 20 minutes that followed — the restart clears the immediate
symptom (flushes the WAL, restores query latency) without necessarily restarting the
compactor goroutine itself. Re-run `make k3s-datastore-health-check` a while after any
restart, not just immediately after, before trusting the incident is actually closed.

For severity triage when something breaks, see [`docs/incident-log.md`](incident-log.md)'s
severity scheme (P0–P3) and its log of real incidents this lab has actually hit.

See [decisions/](decisions/) for the rationale behind these choices.
