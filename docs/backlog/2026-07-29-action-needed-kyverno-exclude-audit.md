# [Action needed] Now/next still gated; Kyverno policy exclude-block audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#841](https://github.com/tooming/k8s-anywhere/pull/841) (cross-backend
Terragrunt consistency audit).

## This cycle's fresh angle

Read every `exclude:` block across the 5 Kyverno `ClusterPolicy` files
(`gitops/kyverno/policies/`) to check whether any carve-out has gone stale
or is broader than its stated justification. Two policies carry namespace
exclusions:

- `add-default-runasnonroot.yaml` / `require-pod-security-restricted.yaml`
  — exclude `kube-system`/`kube-public`/`kube-node-lease` (cluster-managed)
  plus a `namespaceSelector` carve-out — standard, unremarkable.
- `disallow-latest-tag.yaml` — excludes `[capstone, argocd, inkless]`, each
  with a dated, detailed justification comment naming the exact removal
  condition:
  - `capstone`: pending Kargo wiring a real CI-pinned tag (issue #498).
    **Re-verified live**: `gitops/apps/capstone/{deployment,rollout}.yaml`
    both still hardcode `artifactory.127.0.0.1.nip.io/docker-local/
    hello:latest` — the carve-out's condition is still unmet, exclusion
    still correctly in place.
  - `argocd`: pending argo-cd shipping a stable release with PR #26666's
    `/applicationsets` route — **the exact same live-verified TODO this
    run's earlier cycle checked** (`docs/backlog/2026-07-29-action-needed-
    todo-sweep-argocd-latest-tag-recheck.md`): still not shipped in any
    stable release (`v3.4.5`). Carve-out still correctly in place;
    consistent with that earlier finding, not re-litigated from scratch.
  - `inkless`: Aiven Inkless publishes no stable named release, only
    rotating `edge-<commit>` tags — an accepted "intentional
    follow-the-stream" case (same shape as Garage's `main` tag). No stable
    tag exists to pin to; carve-out remains correct.

**Conclusion: no stale or over-broad carve-out found.** All three
`disallow-latest-tag` exclusions are still individually justified by their
own stated, still-true conditions.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake); (d) capstone's Harbor/Kargo cutover
landing (itself gated on #632) would let the `capstone` carve-out be
removed; (e) an argo-cd stable release shipping PR #26666 would let the
`argocd` carve-out (and the separate `global.image.tag: latest` override)
both be removed together.

This note is this cycle's honest record — a genuinely distinct check
(Kyverno policy exclude-block staleness audit) that cross-confirmed one of
its findings against this run's own earlier ArgoCD-TODO verification rather
than re-deriving it. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
