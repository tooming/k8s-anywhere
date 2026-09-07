# Fix a stale "Cilium-enforced" claim in docs/dora-resilience-mapping.md

JANITOR-fallback cleanup (executor STEP 6b), continuing the post-simplification
re-orientation sweep (#1498, #1499, #1500, #1502) into one more doc this pass
hadn't yet checked.

## What was found

`docs/dora-resilience-mapping.md`'s Pillar 1 evidence list described
ADR-0016 as "default-deny NetworkPolicy per namespace, Cilium-enforced." Per
the 2026-09-07 lab simplification, Cilium was removed entirely (ADR-0014,
no replacement) — enforcement moved to k3s's bundled Flannel + kube-router,
already correctly documented in ADR-0016's own "Cilium's removal" section
(added the same day). This one-line evidence citation was the only place in
the file still naming Cilium as the live enforcer.

## What was fixed

Updated the citation to name the real current enforcement mechanism
(Flannel + kube-router) with a pointer to ADR-0016's own fuller mechanics
section, rather than continuing to cite a removed component.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a pure prose
correction, no code/manifest/test touched. Verified directly against
ADR-0016's own current text (its "Cilium's removal (2026-09-07)" section)
before writing the replacement.

## PR

https://github.com/tooming/k8s-anywhere/pull/1503 (chore/dora-resilience-mapping-cilium-stale-fix)
