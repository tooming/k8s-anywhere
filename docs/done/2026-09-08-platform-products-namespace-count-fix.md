# Fix `docs/platform-products.md`'s stale "6 always-on namespaces" claim

Found live 2026-09-08 (cycle 21 of this autonomous run — a fresh lens after
cycle 20's on-demand generated-report currency check: a docs-vs-reality
cross-check specifically on `docs/platform-products.md`, which this run's
prior doc sweeps — cycles 6, 8, 10, 13, 16, 17 — hadn't individually opened
in full). Its intro paragraph said "This lab is now down to 6 always-on
namespaces and nothing on-demand", but the actual post-2026-09-06/07-
simplification count is **4**: `argocd`, `cert-manager`, `lab-gateway`,
`lab-demo` — confirmed against `README.md` ("4 always-on namespaces,
nothing on-demand") and `docs/dependency-tree.md` ("down to exactly 4
always-on namespaces"), both already correct.

This is the identical stale number `docs/decisions/
adr-0016-default-deny-networkpolicy.md` had — fixed earlier this run
(cycle 2, PR history) — but that fix's sweep didn't extend to this file,
which carries the same claim independently.

## What was checked

- Confirmed the correct count (4) against two independently-correct docs
  (`README.md`, `docs/dependency-tree.md`) and the real namespace
  manifests (`gitops/argocd/`, `gitops/network/` [lab-gateway],
  `gitops/cert-manager/`, `gitops/apps/demo/` [lab-demo] — 4
  `namespace.yaml` files at the top level, no more).
- Swept the rest of `docs/platform-products.md` for further staleness: the
  Tier 0/1 mermaid diagram and table, the product catalog (domains A-F),
  the "how to organize the team" squad table, and the maturity-ladder
  section. All already correctly describe the post-simplification state
  (retired domains cite their real ADR numbers and removal dates; nothing
  else references a stale namespace/tier count).
- Considered whether cert-manager and lab-demo's absence from the Tier
  1/product-catalog tables is itself a gap. Concluded it isn't: this doc's
  own definition of a "product" (a consumer-facing self-service contract
  with an owner) already covers cert-manager's *capability*
  (TLS-via-`Certificate`) folded into the Ingress/Connectivity product's
  description ("'certificate' hides cert-manager's root CA chain" — line
  31), and `lab-demo` is a demo workload, not a platform product, so
  neither belongs in a product catalog — matches the same non-gap
  conclusion already reached this cycle's earlier check of the
  `governance` LimitRange mechanism's absence from README's stack table
  (both are internal/non-product surfaces, correctly out of scope for the
  doc that omits them).

## What was done

Changed `docs/platform-products.md`'s intro from "6 always-on namespaces"
to "4 always-on namespaces (`argocd`, `cert-manager`, `lab-gateway`,
`lab-demo`)" — a one-line factual correction, no structural change.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green, including
`markdown-links-check` given the new `docs/done/` cross-link this writeup
itself introduces).

## PR

[#1534](https://github.com/tooming/k8s-anywhere/pull/1534) (autonomous
scheduled executor run, cycle 21 — doc-vs-reality cross-check on a file
not yet individually opened in full this run).
