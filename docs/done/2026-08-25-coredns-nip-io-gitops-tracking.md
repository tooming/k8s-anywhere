# GitOps-track the `harbor.127.0.0.1.nip.io`-class in-cluster DNS rewrite found live in PR #1323 — extend `scripts/coredns-host-alias.sh`

CHARTER **Core Values** §"Everything as code; GitOps deploys it" (ADR-0001);
planner-fallback gap analysis 2026-08-25, reached via `executor.prompt.md` STEP
6b after the "Now / next" lane was re-confirmed fully gated this cycle — both
standing GitLab→Forgejo migration items (rename, decommission) are blocked on
the same live-cluster-design prerequisite the 2026-08-17 investigation already
found (`make up`'s bootstrap sequence and `make rebase-prs`' push path both
still call the GitLab targets directly — a blind rename/removal would break
`make up`), and the capstone-`Deployment`-removal item is still gated on
unconfirmed issue #633 (re-checked this cycle: latest comment 2026-08-25
09:34 UTC still reports it unresolved). No un-groomed intake issue existed
(only the two standing `[Action required]` issues, #633 and #1229) and every
later ROADMAP section was already fully `[x]`, so this was genuine new
gap-analysis output, not a promoted item.

Verified directly (not assumed, ADR-0004): merged PR #1323 (2026-08-25,
`fix(kargo): egress NetworkPolicy targeted wrong namespace+port (#633)`)'s own
body states `harbor.127.0.0.1.nip.io` has no in-cluster DNS answer — nip.io's
real wildcard DNS resolves any of its subdomains to the literal IP in the
name, `127.0.0.1`, which is a pod's own loopback for any in-cluster client,
not the Envoy Gateway — and that the fix was a `coredns-custom` ConfigMap
patch applied live, out-of-band, with the PR body itself flagging: "This
isn't gitops-tracked yet... follow-up issue warranted to bring it under
GitOps management with a drift guard." Grepping `gitops/` confirmed 12
distinct `*.127.0.0.1.nip.io` hostnames (`argocd`, `capstone`, `grafana`,
`harbor`, `kargo`, `kiali`, `longhorn`, `moto`, `rabbitmq`, `rollouts`, `s3`,
`tidb-demo`, `vault`) all route through the single shared Envoy Gateway
(ADR-0008) and share this exact same unresolvable-in-cluster-DNS problem.

## What shipped

Extended `scripts/coredns-host-alias.sh` (same idempotent,
`coredns-custom`-ConfigMap-in-`kube-system` pattern already used for
`host.k3d.internal` — no second parallel script) with a second mode:

- `host-alias` (default, unchanged behavior) — maps `host.k3d.internal` to
  the docker network gateway. Still runs at `make up` step 5, before ArgoCD
  has synced anything.
- `nip-io-rewrite` (new) — discovers Envoy Gateway's generated proxy Service
  in `envoy-gateway-system` via its documented
  `gateway.envoyproxy.io/owning-gateway-{name,namespace}` labels (confirmed
  against Envoy Gateway's own "Gateway Address" docs — this repo's Gateway is
  `eg` in namespace `lab-gateway`), then rewrites `*.127.0.0.1.nip.io` to that
  Service's in-cluster DNS name via a CoreDNS `rewrite name regex` rule. Runs
  as a new `make coredns-nip-io-rewrite` step wired into `make up` right after
  `root-app` — since `root-app` only plants the app-of-apps and returns
  immediately, ArgoCD's sync of `envoy-gateway` (and generation of this proxy
  Service) can still be in flight, so this mode polls up to
  `COREDNS_NIPIO_WAIT` (default 300s) instead of checking once.

**The real footgun this design avoids:** `kubectl apply` replaces a
ConfigMap's `data` map against its own last-applied-configuration, so a call
that only set one of the two keys would silently *delete* the other key on
its next apply. The script now always fetches both keys' current live values
first, recomputes only the key its own mode's prerequisites allow, and
carries the other key's live value forward unchanged — so `host-alias` and
`nip-io-rewrite` can run independently (at different points in `make up`,
different reasons to re-run) without ever clobbering each other.

New/updated coverage in `tests/coredns-host-alias.bats` (15 assertions,
clusterless/structural, verified locally with `bats`): both modes exist and
default correctly; the `owning-gateway` label selector and namespace/name
constants are correct; the poll budget exists; the regex rewrite rule and
target hostname are correct; both ConfigMap keys are always included in every
apply; both Makefile targets exist; `make up` runs `coredns-nip-io-rewrite`
after `root-app`. Also manually dry-ran both script modes against a mocked
`kubectl`/`docker` (idempotent-skip path included) to confirm the runtime
logic — not just the static grep assertions — behaves correctly.

Added a new row (step 10) to `docs/DR.md`'s bootstrap order table, renumbering
the subsequent steps; `tests/bootstrap-seams.bats`'s generic
"every make up sub-target appears in DR.md's bootstrap order table" guard
confirms this stays in sync automatically for any future step.

`make ci`: green — full local run including real `bats` (2881 tests, 0
failures) and every drift/kustomize/terraform check available in this
sandbox.

**ADR-0004 caveat:** this remote clusterless session authored and
structurally/dry-run verified the script and its tests, but could not run it
against a real cluster. The `gateway.envoyproxy.io/owning-gateway-name`/
`-namespace` label convention is Envoy Gateway's own documented mechanism
(its "Gateway Address" task page), not guessed — but the exact behavior on
this lab's live cluster (Service actually appearing within the poll budget,
CoreDNS's `rewrite name regex` syntax resolving as expected) is unverified
until a live-cluster session runs `make coredns-nip-io-rewrite` (or the next
`make up`) for real. Rollback path: revert `scripts/coredns-host-alias.sh` and
the two Makefile targets; `host.k3d.internal` resolution (the pre-existing,
already-verified behavior) is untouched by that revert since it's the
script's unchanged default mode.

## PR

<!-- filled in after opening the PR -->
