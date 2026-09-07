# ADR-0005 — On one host, choose recoverability over (impossible) HA

**Decision.** The lab accepts that it has single points of failure and does **not**
attempt true high availability. Instead it optimizes for **recoverability**
(recreate-from-code) and **resilience** (self-heal, fast restart), and *documents*
the production HA design it would use on real infrastructure.

**Why.** High availability requires ≥2 independent failure domains. On a single
16 GB laptop (one Colima VM) the host is the ultimate SPOF — running two front-door
proxies or two GitLabs on the same machine removes nothing, since they share the one
thing that actually fails. Pretending otherwise would be theatre (cf. ADR-0004).

**The SPOFs, as of 2026-09-07** (see `docs/DR.md`; the blue/green drill and the
DR front door this section used to describe were both removed entirely
2026-09-07, no replacement — there is only one cluster/mode left, not a
blue/green pair):
- **Traefik / k3d load balancer** (`:8080`) — *serving* path, and now the only
  entry point (no separate front-door process any more). Mitigation in-lab:
  Kubernetes restarts a crashed pod automatically (sub-second-to-seconds
  self-heal). Production HA: cloud LB, or an HAProxy/nginx pair sharing a
  keepalived/VRRP virtual IP, fronted by health-checked DNS.
- **GitHub** (this repo's own remote) — *control/recovery* path; a SPOF in the
  recovery path of a DR system. It does NOT take serving down (ArgoCD holds
  last-synced state). Mitigation in-lab: recreate-from-code — `make dr-test`
  (default `SCOPE=cluster`) rebuilds the cluster and re-clones from GitHub
  directly (RTO, not HA; no self-hosted git mirror step is needed any more
  since GitHub itself is already the single source of truth). Full HA: not
  attempted — GitHub's own availability is outside this lab's control.

**Status.** Adopted. Consistent with ADR-0003 (avoid SPOFs *where the topology
allows*) — this ADR is the explicit "RAM/host truly forbids it, so call out the
trade-off" escape hatch that ADR-0003 requires. `make dr-test`/`make up`
recreating the whole lab from git is the recoverability story made executable;
the zero-downtime blue/green drill that used to demonstrate the same idea
without an outage was removed entirely 2026-09-07, no replacement.
