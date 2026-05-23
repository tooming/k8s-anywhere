# ADR-0005 — On one host, choose recoverability over (impossible) HA

**Decision.** The lab accepts that it has single points of failure and does **not**
attempt true high availability. Instead it optimizes for **recoverability**
(recreate-from-code) and **resilience** (self-heal, fast restart), and *documents*
the production HA design it would use on real infrastructure.

**Why.** High availability requires ≥2 independent failure domains. On a single
16 GB laptop (one Colima VM) the host is the ultimate SPOF — running two front-door
proxies or two GitLabs on the same machine removes nothing, since they share the one
thing that actually fails. Pretending otherwise would be theatre (cf. ADR-0004).

**The two SPOFs after a blue→green cutover** (see `docs/DR.md`):
- **Front load balancer** (nginx `:8000`) — *serving* path. Mitigation in-lab:
  `--restart unless-stopped` (sub-second self-heal). Production HA: cloud LB, or an
  HAProxy/nginx pair sharing a keepalived/VRRP virtual IP, fronted by health-checked DNS.
- **GitLab** (omnibus container) — *control/recovery* path; a SPOF in the recovery
  path of a DR system. It does NOT take serving down (ArgoCD holds last-synced state).
  Mitigation in-lab: recreate-from-code — `make dr-test SCOPE=full` rebuilds and
  re-pushes GitLab from the local clone in ~5 min (RTO, not HA). Lighter production
  step: a git **mirror** + ArgoCD `repoURL` failover. Full HA: GitLab Geo (too heavy here).

**Status.** Adopted. Consistent with ADR-0003 (avoid SPOFs *where the topology
allows*) — this ADR is the explicit "RAM/host truly forbids it, so call out the
trade-off" escape hatch that ADR-0003 requires. The blue/green drill
(`make dr-bluegreen-promote`) is the recoverability story made executable.
