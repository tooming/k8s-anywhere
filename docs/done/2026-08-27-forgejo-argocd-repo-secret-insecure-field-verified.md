# Resolve `infra/modules/forgejo-config`'s unverified `insecure` field flag — confirmed correct, not a bug

Bugfix/hardening item, not a ROADMAP item: reached via `executor.prompt.md`
STEP 6b / ROADMAP rule #9 — this run's fourth cycle. Cycles 1–3 each fixed
real, distinct issues (doc-drift table, a Kyverno policy gap) or filed an
honest empty-sweep record; cycle 4 tried yet another fresh lens: an
adversarial read of `infra/modules/forgejo-config/main.tf`, the newest
Terraform module in the repo and one that already carries its own explicit
"UNVERIFIED (ADR-0004)" flag inline.

## What was flagged

The `kubernetes_secret.argocd_repo` resource (the ArgoCD repository-credential
Secret for the SSH-based Forgejo remote, wired but not yet flipped-to-live per
ROADMAP's own gating) sets `data.insecure = "true"`. Its own comment,
written when the module was first authored, flagged this as unverified:
"this field name is this session's best-effort match against ArgoCD's
documented repository-Secret schema from memory... verify ArgoCD actually
accepts/uses this key (vs. e.g. a stale `insecureIgnoreHostKey` alias)."

## Investigation

This clusterless session cannot bring up a live ArgoCD repo-server to test
the field directly — but ArgoCD's own published documentation is an
authoritative, externally-verifiable source that doesn't require one (a
different verification path than a live-cluster check, still real
verification per ADR-0004, same category as this repo's existing practice of
checking a chart's `index.yaml` or a registry's tags API directly rather than
assuming a version). Fetched `argoproj/argo-cd`'s own
`docs/operator-manual/argocd-repositories.yaml` reference example directly:
it states the `insecure` field "does not validate the server's host key or
TLS certificate" and uses it in **both** its SSH and HTTPS repository
examples. Cross-checked against ArgoCD's `Repository` type documentation:
`insecureIgnoreHostKey` is a real, distinct field on the same type, but
**deprecated** in favor of the newer, unified `insecure` field.

## Conclusion: no bug, existing code is correct

`insecure = "true"` was already the right field for this SSH-based
repository Secret. Using `insecureIgnoreHostKey` instead — the exact
alternative the original comment named as a possible fix — would have been
a regression to the deprecated field name, not an improvement. Good thing
this was verified before "fixing" it.

## What changed

- Updated `infra/modules/forgejo-config/main.tf`'s comment from "UNVERIFIED"
  to a dated, sourced confirmation citing the exact upstream doc and the
  deprecation finding, so a future session doesn't re-flag or "fix" this
  again without doing the same check.
- Added a regression guard to `tests/forgejo-config.bats`: asserts the
  Secret's `data` block contains `insecure = "true"` and does **not**
  contain `insecureIgnoreHostKey`, so a future edit can't silently swap in
  the deprecated field name.

No functional/behavioral change — this resource is still not wired into any
live Application `repoURL` (unchanged, per the same comment's own "Deliberately
NOT wired up yet" note, which this PR does not touch).

## Verification

`bats tests/forgejo-config.bats` — 15/15 pass (new test included). Full
`make ci` with the real `mikefarah/yq` binary on `PATH` (same setup as
cycle 3's PR) — 2781 lines of gate output, zero `not ok`, exit 0.

## PR

https://github.com/tooming/k8s-anywhere/pull/1353
