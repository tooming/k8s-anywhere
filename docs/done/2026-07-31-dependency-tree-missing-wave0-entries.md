# Add missing wave-0 Applications to dependency-tree.md + fix stale PSA claims

Following up on the PR #949 note about `argocd-extras`/`kargo-extras`/`trivy-extras`
being absent from `docs/dependency-tree.md`'s apply-order table, did the full
verification this time. Every wave-0 `argocd.argoproj.io/sync-wave: "0"` Application
was enumerated directly from `gitops/platform/*.yaml` (16 total) and cross-checked
against the table. Found:

1. **`kargo`, `kargo-extras`, `kargo-project` entirely missing** — same bug class as
   the just-fixed `istio-system-extras` gap: `kargo` (chart `kargo` v1.11.0, ADR-0023)
   is on-demand (manual-sync, confirmed via `grep -c automated: gitops/platform/kargo.yaml`
   → 0), so `kargo-extras` (wave 0, always-on namespace floor) should have gotten a
   dedicated "—" row like harbor-extras/longhorn-extras/tidb-admin-extras/
   istio-system-extras — none of the three (`kargo`, `kargo-extras`, `kargo-project`)
   were in the table at all, only in the mermaid diagram and NetworkPolicy table.

2. **`argocd-extras`, `kyverno-extras`, `trivy-extras` missing from wave-0's inline
   list** — their heavy siblings (kyverno, trivy-operator are always-on; argocd itself
   is the Terraform-bootstrapped control plane) mean these belong inline in row 306
   like `cert-manager-extras`/`velero-extras`, not a dedicated "—" row.

3. **Stale PSA level while verifying #2**: the doc's existing Kyverno prose (and my own
   first draft of the new wave-0 text) claimed `kyverno-extras` applies PSA `baseline`
   labels — but `gitops/kyverno/namespace.yaml`'s actual labels are `restricted` (all
   four fields), and ADR-0019 itself documents the `baseline` → `restricted` flip on
   2026-07-17 per RFC #483. The doc's Kyverno paragraph had never been updated after
   that flip.

4. **Stale PSA-phase claim in `gitops/platform/argocd-extras.yaml`'s own header
   comment**: it said the Application patches only "Phase 1 PSA warn/audit labels"
   with "Phase 2 (enforce flip...) a separate 🟡 item awaiting infra/ changes" — but
   `gitops/argocd/namespace.yaml`'s own comment and actual labels show Phase 2 (full
   `restricted` enforce/warn/audit) already shipped, citing PR #493's audit. The
   Application's comment was never updated after that later PR landed.

## Fix

- Added `kargo *(on-demand)*`, `kargo-extras *(auto-synced, wave 0)*`, and
  `kargo-project *(on-demand, wave 6)*` rows to the apply-order table (next to the
  other on-demand components).
- Added `argocd-extras`, `kyverno-extras`, `trivy-extras` to wave-0's inline list
  (row 306), with accurate current-state descriptions (not stale ones).
- Corrected the existing Kyverno paragraph's stale `baseline` claim to `restricted`.
- Corrected `gitops/platform/argocd-extras.yaml`'s header comment to describe the
  current Phase-2 state instead of the superseded Phase-1 status.

New recurrence-guard assertions in `tests/kargo.bats`, `tests/kyverno.bats`,
`tests/trivy-operator.bats`, `tests/argocd-resources.bats`: each asserts the doc
contains the correct current-state string, and one explicitly asserts the stale
"Phase 1 warn/audit labels" string is *absent* from `argocd-extras.yaml`.

Doc + comment-only changes — no manifest field values or behavior changed (PSA labels
on the actual namespaces were already `restricted`; only the *descriptions* of that
state were stale).

**Blast radius on a live cluster:** none.

`make ci` passes.

## PR

(filled in after PR creation)
