# ADR-0003 — Production-shaped, decoupled designs; no single-pod SPOFs

**Decision.** Prefer decoupled, distributed, scalable topologies over the simplest
single-pod option — even in the lab. If RAM truly forbids it, call out the
trade-off explicitly rather than silently shipping the toy option.

**Why.** Build it the way real platforms are built; that's the point of the lab.

**Canonical example.** Metrics use the decoupled Grafana LGTM pattern —
**Alloy** (collector; DaemonSet for node/pod + a small cluster-scrape instance)
→ **Mimir** (separate store) → **Grafana** — NOT a monolithic single-pod
Prometheus (which couples scrape + storage + query and is a SPOF). Storage is
externalized to Garage S3; the ingester WAL is on a PVC so data survives restarts.

**Status.** Adopted. Consistent with ADR-0001 (GitOps) and ADR-0002 (Garage).
