# Extend `docs/dependency-exit-runbooks.md` (DORA audit Q17) to the four highest-blast-radius remaining single-tool rows — Cilium, Garage, Envoy Gateway, cert-manager

(CHARTER **Core Values** §"Everything as code" (DORA audit readiness Q17);
planner-fallback gap analysis 2026-09-02, this run's fourth cycle, reached via
`executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
gated this cycle (same blockers as the three prior cycles this run) and
PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER all came up empty
again. Fresh angle: continued mining `docs/dora-audit-readiness.md` — this run's
third pass over it — for another real, previously-untouched, explicitly-named
gap. `docs/dependency-exit-runbooks.md`'s own "Scope of this slice" note already
named the eleven remaining `always-on-core` single-tool rows as "real,
separately-scoped future work if wanted" — picked the four highest actual
blast-radius ones (CNI, storage, ingress, TLS) rather than all eleven, to stay
within WAYS-OF-WORKING.md §3's size discipline, matching this file's own existing
scoping precedent. **No prerequisites — executor may pick up immediately.**)

## What was found

`docs/dependency-exit-runbooks.md`'s own "Scope of this slice" note (written when
the file was created for Q16's three concentration groups) explicitly named eleven
remaining `always-on-core` single-tool rows as real, separately-scoped future
work. Of those eleven, four carry the actual highest operational blast radius if
they ever needed replacing: Cilium (every pod's network path), Garage (the only
stateful S3-compatible store), Envoy Gateway (the sole ingress path for every UI),
and cert-manager (TLS issuance — a silent, not immediate, failure mode).

## Fix

Added four single-paragraph runbook entries to `docs/dependency-exit-runbooks.md`
(leaner than the existing three-paragraph group entries, since each is a single
tool, not a multi-tool group), each covering: what a real exit changes
mechanically, whether it's fork-and-repoint or a real migration, and whether an
exit-direction alternative has been evaluated (honestly "no" for all four,
distinct from each ADR's own original rejected-alternative record at adoption
time).

Verified each citation directly against the real repo, not assumed (ADR-0004):
- Cilium: confirmed `gitops/platform/cilium.yaml` is Terraform-bootstrapped
  (ADR-0001's day-0 seam), same tier as ArgoCD itself, not a `gitops/`
  `Application`.
- Envoy Gateway: confirmed `gitops/platform/envoy-gateway.yaml` is sourced via a
  Kustomize-vendored chart per its own header comment (the probe-timeout /
  disabled-leader-election fix).
- cert-manager: confirmed directly against ADR-0028's own text — it explicitly
  states no prior ADR evaluated or rejected an alternative, so "no exit-direction
  alternative evaluated" is not an assumption.
- Garage: confirmed `gitops/platform/garage.yaml` is a normal auto-synced
  `Application`, and that Velero backups, Mimir/Loki/Tempo chunk storage, and
  off-cluster Terraform state (ADR-0007) all target it directly.

Updated the file's own "Scope of this slice" note to name the four newly-covered
rows and the seven still remaining (Terraform/Terragrunt, RabbitMQ, Valkey, KEDA,
Forgejo, kube-state-metrics, node-exporter). Also caught and fixed a now-stale
claim in `docs/dora-audit-readiness.md`'s own Q17 gap text, which previously
listed all eleven remaining single-tool rows as uncovered — no longer accurate
for four of them; fixed in the same pass rather than left stale (ADR-0004).
Added `tests/dora-audit-readiness.bats` coverage confirming all four new entries
are present.

`make ci` / local: `tests/dora-audit-readiness.bats` (12/12), `lint`
(shellcheck + yamllint), `markdown-links-check`: green.

**ADR-0004 caveat:** this is a documentation-only change (no manifest, no
Application, no code) — nothing here is asserted as deployed or verified live;
every claim about the current repo state (file locations, ADR text, Kustomize
sourcing) was checked directly against the files themselves this cycle.

## PR

https://github.com/tooming/k8s-anywhere/pull/1378
