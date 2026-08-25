# Reconcile docs with the KEDA/KRO on-demand conversion (PR #1300)

CHARTER **Core Values** §"Everything as code" / "Docs & dashboards don't drift"
+ ADR-0004 (no fabricated content). Executor-direct doc-drift fix, reached via
`executor.prompt.md` STEP 6b after this run's "Now / next" lane was found
fully gated (all three unchecked ROADMAP items re-checked, still gated on
issue #633) and the PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER fallback passes all found nothing. Widened the lens per STEP 8's
guidance to try something not yet tried this run: checking whether the most
recently merged PR (#1300, KEDA + KRO always-on → on-demand conversion,
merged the morning of this run) left any doc claims stale.

## What was stale

PR #1300 converted KEDA (engine + namespace + NetworkPolicy overlay + its
`data-demo-keda-scaling` ScaledObject demo, all four Applications) and KRO's
own controller Application (but not its `kro-extras`/`kro-resources`
namespace/RBAC plumbing) from always-on/auto-synced to on-demand — but only
updated `docs/dependency-register.md` and ADR-0029's own Re-evaluation log.
Several other docs still asserted the pre-conversion state as current fact:

- `CHARTER.md` — "Always-on core... ~33 ArgoCD Applications" (now ~32: KRO's
  engine left the auto-synced set, though its extras/resources plumbing
  stays); the KEDA bullet said "Engine is auto-synced" (now false).
- `docs/dora-audit-readiness.md` — derived "~58 Applications are load-bearing"
  / "CHARTER's own bullet count is ~33 of those 58" (now ~53 / ~32 — KEDA's
  four Applications left the auto-synced set entirely).
- `README.md` — the Autoscaling row didn't mention KEDA is now `make
  keda-up`/`make keda-down`; the Cloud/platform-eng row didn't mention KRO's
  controller is suspended.
- `docs/00-architecture.md` — KEDA and KRO rows both described the
  pre-conversion always-on state.
- `docs/dependency-tree.md` — the largest gap: the mermaid subgraph still
  labeled KEDA "always-on"; the ArgoCD apply-order wave table still listed
  `keda`/`keda-extras`/`keda-networkpolicy` at wave 6 and
  `data-demo-keda-scaling` at wave 7 as if auto-synced by wave, and still
  listed `kro` in wave 3; a full prose paragraph asserted KEDA "is
  **always-on / auto-synced**".

## Method

Verified directly against the actual repo (ADR-0004), not assumed: parsed
every `kind: Application` manifest under `gitops/` for a real (non-null)
`spec.syncPolicy.automated` field using a real YAML parse (not a text/substring
match — this repo has been burned by false positives from that before, per
issue #846's own `docs/done/` record). **58** matched (down from the
`docs/done/2026-08-24-...`-verified 63, i.e. `docs/backlog/2026-08-24-*-cycle9-*`'s
same-day re-confirmation) — exactly `keda`, `keda-extras`, `keda-networkpolicy`,
`data-demo-keda-scaling`, and `kro`'s own engine all confirmed absent from the
auto-synced set; `kro-extras`/`kro-resources` confirmed still present.
Re-applied the identical five-bucket categorization from issue #846/PR #849
(and re-confirmed by the 2026-08-24 cycle-9 sweep): Always-on core 33→32 (KRO's
engine left, its extras/resources plumbing stays counted here, matching the
harbor-extras "PSA floor" pattern); cert-manager+KEDA 8→4 (KEDA's four gone
entirely); next-wave 14, capstone 3, PSA-floor shells 5 unchanged. New total:
32+14+4+3+5 = 58, matching the raw auto-synced count exactly.

## What changed

Pure prose reconciliation — no manifest/behavior change, no gate touched:

- `CHARTER.md` — `~33`→`~32` with the re-derivation note; KEDA bullet
  rewritten to describe on-demand status.
- `docs/dora-audit-readiness.md` — `~58`→`~53`, `~33 of those 58`→`~32 of
  those 53`, KEDA dropped from the "rest are" list.
- `README.md` — Autoscaling row gets the `make keda-up`/`make keda-down`
  note; Cloud/platform-eng row notes KRO's controller is suspended.
- `docs/00-architecture.md` — KEDA and KRO rows updated to current state.
- `docs/dependency-tree.md` — mermaid KEDA subgraph relabeled on-demand
  (`:::ondemand` styling, matching Harbor/Istio/Cilium); KRO's cloud-subgraph
  node label notes the suspension; wave table: removed keda/keda-extras/
  keda-networkpolicy from wave 6 (wave 6 now just `lab-gateway-certificate`),
  removed the now-empty wave 7 row, removed `kro` from wave 3, added five new
  `— | <name> *(on-demand...)*` rows for keda/keda-extras/keda-networkpolicy/
  data-demo-keda-scaling/kro mirroring the existing harbor/kargo on-demand +
  auto-synced-extras row pattern; the KEDA prose paragraph rewritten in full
  to describe on-demand status; the data-demo prose paragraph's wave-7
  citation updated; a data-namespace NetworkPolicy note now flags the
  keda-sourced ingress rule as dormant while KEDA is down.

## Explicitly out of scope

Found but deliberately not fixed here (a distinct, non-doc issue, better as
its own bounded change): `gitops/platform/governance-appset.yaml` still lists
a `keda-governance` entry with `CreateNamespace=true`, which — now that
`keda-extras` no longer auto-creates the `keda` namespace — would have ArgoCD
recreate an otherwise-empty `keda` namespace (just a LimitRange, no workload)
on every reconciliation, working against the "fully on-demand, zero
footprint" intent of PR #1300's own conversion. Low severity (a stray empty
namespace, not a functional break) but a real manifest gap, not documentation
— left for a separate cycle's own bounded fix.

`make ci`: green (full local run; no manifest/test file touched, so bats/
kustomize/terraform — not installed locally — are unaffected by this diff).

## PR

https://github.com/tooming/k8s-anywhere/pull/1311
