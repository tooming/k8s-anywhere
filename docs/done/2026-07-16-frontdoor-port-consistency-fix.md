# Front-door port consistency fix (`:8080` → `:8000`) + a hard sandbox-limits finding

Triggered by a new session goal: "make `make up` work." Attempted the most direct
interpretation — actually running `make up` — before falling back to static audit.

## What was attempted

Started a real Docker daemon in this sandbox (`dockerd`, via an explicitly elevated,
un-sandboxed Bash call) to see how far a live bootstrap could get. It started cleanly
and `docker info` reported a healthy 15 GB RAM / 26 GB disk / 4-CPU environment —
plausibly enough to run at least the always-on stack. Installed the missing CLI
tooling (`terragrunt`, `k3d`, `kubectl`, `vault`, `cosign` — via `go build` against
local git clones where `go install <pkg>@version` hit "go.mod contains a replace
directive" errors, and via direct binary downloads from `dl.k8s.io` /
`releases.hashicorp.com` where those were reachable).

**Blocked at the first real step.** `make tfstate-up`'s `docker compose up` failed
pulling `dxflrs/garage:v2.3.0` — `production.cloudfront.docker.com` returned 403.
Confirmed with a maximally boring control case (`docker pull alpine:3.20`) that this
is not image-specific: **every** container image pull is denied. The proxy's own
`/__agentproxy/status` endpoint confirms this is a hard organizational egress-policy
denial (`"gateway answered 403 to CONNECT (policy denial or upstream failure)"`),
explicitly documented as "do not retry or route around it." This is the same class of
restriction as the already-known Helm-chart-repo-index blocks this ROADMAP documents
repeatedly, just discovered to extend to raw image pulls too — meaning a live
`k3d`/GitLab/ArgoCD cluster is not just inconvenient but **structurally impossible**
to stand up from this sandbox, regardless of which CLI tools are installed. Stopped
`dockerd` cleanly once this was confirmed rather than continuing to poke at a
policy-level wall.

## What shipped instead

Pivoted to the same static-audit technique that already caught the KEDA wave-ordering
deadlock (#445) — read the bootstrap chain for real, verifiable bugs rather than
attempting a live run. Found a genuine, repo-wide inconsistency: several scripts and
`Makefile` targets hardcode the per-cluster Envoy port `:8080` (blue's own
host-mapped port) instead of the stable DR front door `:8000`
(`scripts/bluegreen-frontdoor.sh`) — even though `make up`'s own completion banner and
`docs/DR.md` both document `:8000` as the canonical, cutover-survivable entry point,
and `docs/DR.md` explicitly says `:8080` "is gone with blue" after a promotion.

On a fresh single-cluster `make up`, `:8080` and `:8000` happen to reach the same
backend, so this wasn't breaking the literal bootstrap — but it's a real, immediate,
user-visible inconsistency (`make up` advertises `:8000`; the very next thing a user
might run, `make creds`, printed `:8080` login URLs) and a real breakage after any
blue/green cutover (`make health`/`make creds`/a re-run of `grafana-gitsync-bootstrap`
would silently probe a port that no longer exists).

Fixed all of them to use `:8000` consistently:
- `Makefile`'s `creds` target (ArgoCD/Grafana/Vault/RabbitMQ URLs) and `argocd-ui`'s
  comment.
- `scripts/lab-health-check.sh`'s default `UI_PROBES` (the literal final gate `make up`
  itself runs) + its comments.
- `scripts/grafana-gitsync-bootstrap.sh`'s default `GRAFANA_URL` + comment.

Added recurrence-guard bats assertions in `tests/lab-ops-scripts.bats` and
`tests/bootstrap-seams.bats` pinning `:8000` and explicitly rejecting `:8080`/`:8082`
in each of these defaults, so a future edit can't silently reintroduce a
per-cluster port here.

## Verification

`bats tests/lab-ops-scripts.bats tests/bootstrap-seams.bats` — 56/56 pass. Full
`make ci` green. Live execution (the actual ask) remains untested — and untestable —
in this sandbox for the structural reason above; a session running on the
maintainer's own machine (real internet access, no egress policy) is the only way to
verify `make up` end-to-end.

## PR

https://github.com/tooming/k8s-anywhere/pull/446
