# Bump kube-state-metrics `8.4.0` → `8.4.1` and node-exporter `4.56.1` → `4.56.3`

(CHARTER **Core Values** §"Everything as code" + general hardening; upgrade-drafter fallback, executor.prompt.md STEP 6b — this run's twelfth cycle: the "Now / next" lane remained fully gated and PLANNER found no ungroomed intake or un-RFC'd 🟡 item. Routine currency sweep re-checked the two observability exporters last reviewed 2026-08-20.)

Both verified directly (not assumed, ADR-0004) via a sparse clone of `prometheus-community/helm-charts` (the same repo hosts both charts).

## kube-state-metrics `8.4.0` → `8.4.1`

Tagged `Chart.yaml` at `kube-state-metrics-8.4.1` shows `version: "8.4.1"`, `appVersion: "2.20.0"` (unchanged app version — chart-only bump). `git diff` between the two tags' `values.yaml` is purely additive: new commented-out opt-in collector entries (`validatingadmissionpolicies`, `validatingadmissionpolicybindings`, `mutatingadmissionpolicies`, `mutatingadmissionpolicybindings`, all disabled by default) plus a doc-comment rewording. No `valuesObject` key this lab sets changed shape.

## node-exporter `4.56.1` → `4.56.3`

Tagged `Chart.yaml` at `prometheus-node-exporter-4.56.3` shows `version: "4.56.3"`, `appVersion: "1.12.1"` (unchanged). `git diff` between the two tags' `values.yaml` shows two changes: (1) an additive `kubeRBACProxy.listenHost` default (no behavior change — this lab doesn't enable `kubeRBACProxy`); (2) a **real default behavior change** — `extraArgs` moves from empty to two new filesystem-collector exclusion flags that filter pseudo/container filesystems (overlay, proc, tmpfs-family, container-runtime mount paths) out of `node_filesystem_*` metrics. This lab sets no `extraArgs` override, so it inherits the new default. Checked `grafana/dashboards/lab-node-exporter.json` directly: only two `node_filesystem_*` metrics are queried, both for real host disk usage — excluding pseudo-filesystem noise is a genuine improvement, not a regression.

Both Applications are **ALWAYS-ON** (automated sync) — these pins take effect on the next ArgoCD reconciliation.

Bumped both `gitops/platform/observability-ksm.yaml`/`observability-node-exporter.yaml`'s `targetRevision` and header comments. Updated `tests/securitycontext-observability.bats`'s KSM pin assertion (retitled, added a negative assertion). Updated [ADR-0034](../decisions/adr-0034-lgtmp-observability-stack.md)'s two table rows and appended two new dated entries to its Re-evaluation log. Updated `docs/dependency-register.md`'s two rows.

**ADR-0004 caveat.** This remote clusterless session cannot verify either exporter's pods actually restart cleanly on the new chart versions on a live cluster, or that the "Lab — Node Exporter"/stack-health dashboards keep populating post-bump. Rollback path: revert both `targetRevision` values (`8.4.0` / `4.56.1`).

## PR

https://github.com/tooming/k8s-anywhere/pull/1371
