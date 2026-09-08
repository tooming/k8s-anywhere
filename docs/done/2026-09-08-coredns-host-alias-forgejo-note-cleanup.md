# Correct `scripts/coredns-host-alias.sh`'s header comment (and `docs/DR.md`/`docs/dependency-tree.md`'s bootstrap-step descriptions) to note the `host.k3d.internal` alias was built for Forgejo's local repoURL

Found live 2026-09-08 (planner gap analysis, same "leftover rationale from a
removed component" class as this run's earlier ADR-0016/0017 (#1514) and
dead-Harbor-mirror (#1516) fixes): the script's own header still explained
the alias purely in terms of "every ArgoCD Application (whose repoURL
points at the local Forgejo via `http://host.k3d.internal:2223/...`)" — but
`gitops/bootstrap/root-app.yaml`'s `repoURL` is
`https://github.com/tooming/k8s-anywhere.git` (a public HTTPS host,
resolvable via any standard DNS, not a docker-network-local address). A
repo-wide grep for `host.k3d.internal`/`host-k3d-internal` outside
`Makefile`, the script itself, and historical `docs/done/` writeups finds
zero consumers in any live-synced `gitops/**`/`infra/modules/argocd/**`
path.

Forgejo is gone (ADR-0035), ArgoCD now syncs from a public GitHub
`repoURL`, and this alias's continued necessity is unconfirmed pending live
verification (tracked in
[#1517](https://github.com/tooming/k8s-anywhere/issues/1517)).

**Scope of this item (🟢, safe, docs/comment-only, no behavior change):**
update the script's header comment and the two docs' bootstrap descriptions
to state plainly that the alias was Forgejo-era, is currently unreferenced
by anything live in the repo, and its removal is gated on live confirmation
via issue #1517 — do **not** remove the `coredns-host-alias` Makefile
target, the `make up` step that calls it, or the script's `host-alias` mode
itself in this item; that removal is issue #1517's job once a
live/interactive session confirms `make up` still succeeds without it
(this remote clusterless session cannot run `make up` to verify — ROADMAP
rule #2).

## What was done

- `scripts/coredns-host-alias.sh`: rewrote the header comment's `host.k3d.internal`
  explanation to state the alias was originally load-bearing for Forgejo's
  repoURL, that Forgejo is gone and ArgoCD now uses a public GitHub `repoURL`,
  that a repo-wide grep finds zero remaining consumers, and that removal is
  gated on live verification via issue #1517. Also corrected a separate,
  adjacent stale reference in the same file: the `Usage` section's
  `host-alias` mode described itself as "step 5" of `make up` — the real
  current step (per `docs/DR.md`'s own numbered table and the `Makefile`'s
  `up` target order) is step 3; corrected.
- `tests/coredns-host-alias.bats`: its own header comment carried the same
  stale "needed for ArgoCD's Forgejo repoURL" phrasing (descriptive only,
  asserted by no test) — corrected to match, citing issue #1517.
- `docs/DR.md`: step 3's row in the bootstrap-chain table appended the same
  Forgejo-removed / unconfirmed-necessity / issue #1517 note.
- `docs/dependency-tree.md`: added a footnote below the bootstrap-chain
  ASCII diagram with the same note (the diagram itself isn't a good place
  for a multi-line explanation). Also fixed a separate, unrelated-but-
  adjacent stale reference found while editing this diagram: step 6
  (`coredns-nip-io-rewrite`) still said `*.127.0.0.1.nip.io -> Envoy` —
  Envoy Gateway was replaced by Traefik (ADR-0040); corrected to `-> Traefik`.
  Verified no bats test asserts the old "-> Envoy" text.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green), confirming none of these
comment/doc edits broke any mechanical assertion.

## PR

[#1519](https://github.com/tooming/k8s-anywhere/pull/1519) (autonomous
scheduled executor run, cycle 6: item picked directly from the
freshly-refilled "Now / next" lane after cycle 5's `plan/*` PR #1518).
