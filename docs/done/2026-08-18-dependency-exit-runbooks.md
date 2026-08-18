# Dependency exit runbooks for the lab's top concentration risks — closes DORA audit Q17's named gap

CHARTER **Core Values** §"Everything as code; GitOps deploys it" + operational-
resilience discipline. Executor pickup of the topmost 🟢 *Now / next* item, which this
same run had authored one cycle earlier via the PLANNER fallback role
(`executor.prompt.md` STEP 6b, PR #1241) after finding the lane fully gated on
unconfirmed maintainer-confirmation issue #633 and the two GitLab-migration items.

## Item description (as it stood in ROADMAP.md)

**Dependency exit runbooks for the lab's top concentration risks — closes DORA audit
Q17's named gap.** Verified directly (not assumed, ADR-0004): `docs/dora-audit-
readiness.md` Q17 named this exact gap — exit strategy is "implicit" (ADR-0001) and
"demonstrated" once (the real, executed ADR-0011→ADR-0024 Artifactory→Harbor
migration), but "no dependency has a written exit runbook in advance of needing one."
`docs/dependency-concentration.md` (Q16) already named which upstream orgs
concentrate risk but not how to exit any of them.

## What was built — and one deliberate scope cut

Added `docs/dependency-exit-runbooks.md` covering exactly the three concentration
groups `docs/dependency-concentration.md` names: `github.com/grafana` (6 tools —
Grafana, Mimir, Loki, Tempo, Pyroscope, Alloy), `github.com/argoproj` (2 tools —
ArgoCD, Argo Rollouts), `github.com/pingcap` (2 tools — TiDB Operator, TiDB). Each
section states: what a real exit changes mechanically in `gitops/` (which
`Application` manifests, chart `repoURL`/`targetRevision` values); whether it's a
fork-and-repoint or a real schema/data migration (explicitly graded per group — the
Grafana-org storage components and ArgoCD's own CRD vocabulary are real migrations,
not simple repoints; Grafana the UI and the on-demand-only TiDB pair are the most
fork-and-repoint-shaped); and, honestly, that no alternative has actually been
evaluated for any of the three yet — the first real step of any exit is the same
ADR-writing process ADR-0002/ADR-0018/ADR-0024 already used to pick a tool, not an
assumed replacement.

**Deliberate scope cut from the original item text:** the ROADMAP item also asked for
"any single-tool row the register's own criticality column marks `always-on-core`
that isn't already covered by one of those three groups" — eleven more rows
(Terraform/Terragrunt, Garage, Envoy Gateway, RabbitMQ, Cilium, Valkey, cert-manager,
KEDA, Forgejo, kube-state-metrics, node-exporter). Writing a real (non-padding)
runbook section for all eleven in the same PR would have pushed this well past
WAYS-OF-WORKING.md §3's per-PR size discipline. Following ROADMAP rule #9's own
split-the-gate convention, this PR ships the three named concentration groups — the
lab's actual highest-blast-radius exit candidates, and what the item's own title
promised ("top concentration risks") — and states the cut plainly in both the new
file's own "Scope of this slice" section and here, rather than silently narrowing
the claim (ADR-0004: an unscoped "covers dependencies" title would itself overclaim
completeness). Extending to the eleven remaining singles is named as real,
separately-scoped future work if wanted.

Updated `docs/dora-audit-readiness.md` Q17's Answer/Evidence/Gap: exit strategy is
now pre-planned (not just implicit) for the three groups, with the Gap narrowed to
name exactly the eleven-row extension that's still open, and an explicit caveat that
a written runbook doesn't make a real exit's effort smaller — only its first-response
steps are already identified. Added a "Keeping this in sync" cross-reference in
`docs/dependency-concentration.md` noting the new file is a downstream consumer of
its three groups.

`tests/dora-audit-readiness.bats` — extended (not a new file; this doc already had
one) with 3 new assertions: the runbooks file exists; it names all three concentration
groups; Q17's Gap line points at the new file rather than the old purely-reactive
wording. Full file: 11/11 passing locally.

## ADR-0004 caveat

None of the three runbooks assert any exit has actually been rehearsed — each
section explicitly states "no alternative evaluated yet" rather than implying a
decided replacement. This is a planning artifact, not a claim that any migration is
smaller or safer than it actually would be.

## PR

#1242 — https://github.com/tooming/k8s-anywhere/pull/1242
