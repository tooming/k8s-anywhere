# Planner-note migration — accreted "Now / next" header notes (through 2026-06-20)

This file preserves the per-run **planner-note** commentary that had accreted
*inline at the top of* the `ROADMAP.md` `### Now / next` section. The original
conflict-prevention change (PR #209, `docs/backlog/2026-06-15-footer-migration.md`)
externalized the `## Backlog` **footer** paragraph, but the binding rule only
named the footer — so subsequent planner runs relocated their per-run notes to a
**header** block at the top of *Now / next* instead, reintroducing the exact same
merge conflict (two planner runs on 2026-06-20, PRs #235 and #236, collided on
this anchor — see PR #236).

This migration externalizes those header notes too, and the binding rule + a new
`make ci` guard (`scripts/roadmap-check.sh`) now forbid **any** inline
`**Planner note (…)**` block anywhere in ROADMAP.md. No content is lost; new runs
add their own dated file under `docs/backlog/` instead of editing this shared
anchor.

The notes below are preserved verbatim, in chronological order.

---

## Planner note (2026-06-11 — Tier 1 next-wave fan-out + O2 tail)

The 2026-06-08 O2 fan-out wave has fully landed (capstone/data/vault/observability
NetworkPolicies + PSS for capstone/data/observability + PSS labels for
vault/storage/tidb/tidb-admin + storage/argocd/moto/ack/lab-gateway NPs —
all in *Done*). Two architect waves landed this week: (a) all four Tier 1
next-wave ADRs are merged — ADR-0019 (Kyverno), ADR-0020 (Argo Rollouts),
ADR-0021 (Velero), ADR-0022 (Trivy Operator); and (b) RFC issues #153–#156
carry the binding implementation specs. Per WAYS-OF-WORKING.md §2, the
architect's decision *is* the approval — the planner grooms each RFC's
*Acceptance criteria* into 🟢 single-PR executor items here, no human-RFC
step needed.

## Planner note (2026-06-14 — O1/O5 dashboard tail + O4/O6 RFC surface)

Two deferred Tier 1 next-wave Grafana dashboards are now the highest-value 🟢 items:
the Argo Rollouts dashboard + Alloy scrape job (explicitly deferred in
`docs/done/2026-06-13-argo-rollouts-controller.md`; NP ingress pre-wired) and the
Trivy Operator dashboard (explicitly deferred in `docs/done/auto-trivy-operator.md`;
Alloy scrape already wired). Both are required by CHARTER O1 ("each next-wave
component … with real-metric Grafana dashboard") and O5 ("every always-on component
has a real-metric dashboard by 2026-09-30"). The tidb/tidb-admin NetworkPolicy
fan-out (the last O2 tail item) is in-flight as PR #203. Two new 🟡 Cross-cutting
entries below surface the remaining O4 work (cosign signing in GitLab CI +
verifyImages Enforce flip) and O6 work (make capstone-demo wall-clock target), both
awaiting architect RFCs before the planner can groom them into 🟢 executor items.

## Planner note (2026-06-16 — RFC #214 + #215 groomed into 🟢 O4/O6 items)

Architect run 2026-06-16 filed RFC #214 (O4: cosign CI signing + verifyImages Enforce
flip) and RFC #215 (O6: `make capstone-demo` wall-clock target). Both are now groomed:
four new 🟢 items added below — three from RFC #214 (cosign `make up` wiring → CI sign
stage → verifyImages Enforce flip, in that dependency order) and one from RFC #215
(capstone-demo target, standalone). The two formerly-🟡 Cross-cutting O4/O6 entries are
marked "Groomed ↗".

## Planner note (2026-06-18 — O5 gap: External Secrets dashboard; O2 gaps surfaced to architect)

Gap analysis found one new 🟢 O5 item: the `external-secrets` Application
is auto-synced but has no Alloy scrape job and no Grafana dashboard — inserted above the
two blocked items so the executor lane stays active. Two new 🟡 O2 items surface PSS
gaps in the `external-secrets` and `envoy-gateway-system` namespaces (both absent from
ADR-0017 §"Per-namespace profile"; both need architect RFCs before the planner can groom
them into 🟢 items). The two existing blocked items (ArgoCD PSS Phase 2 + verifyImages
Enforce flip) remain unbuilt — each requires explicit maintainer cluster confirmation
before the executor may proceed (noted in their item text).

## Planner note (2026-06-20 — RFC #229 + #230 groomed into 🟢 O2 PSS items)

Architect run 2026-06-19 filed RFC #229 (O2: PSS `restricted` for `external-secrets`) and
RFC #230 (O2: PSS `baseline` for `envoy-gateway-system`). Both are now groomed into two new
🟢 items added below, ordered before the blocked items so the executor has actionable work.
The two formerly-🟡 Cross-cutting entries are marked "Groomed ↗". After these two land,
the remaining always-on O2 gaps are ArgoCD PSS Phase 2 (needs cluster verification) and
the verifyImages Enforce flip (needs `.sig` tag confirmation) — both noted in their items.

## Planner note (2026-06-20 — O5 gap-fill: observability infrastructure dashboards)

Gap analysis found three auto-synced Applications that lack a `lab-*.json` dashboard,
violating CHARTER O5 ("every Application in root-app.yaml's auto-synced set has a
real-metric dashboard by 2026-09-30"): `observability-alloy`, `observability-ksm`,
`observability-node-exporter`. All are confirmed auto-synced (no `# ON-DEMAND:` guard);
KSM and Node Exporter metrics are already scraped; Alloy needs a self-scrape job
added before a dashboard can meet ADR-0004. Three new 🟢 items added at the tail of
*Now / next* below. Full analysis in `docs/backlog/2026-06-20-o5-observability-gap.md`.

## PR

PR (this migration) — adds `scripts/roadmap-check.sh` as a `make ci` gate so the
inline-note pattern can never reaccrete.
