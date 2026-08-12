# [Action needed] Now/next still gated; fallback chain exhausted, cycle 3 (post-guard)

**Date:** 2026-08-12
**Cycle:** 3rd cycle this run, after PR #1171 (`upgrade/ksm-chart-8-2-0-to-8-3-0`,
cycle 1's real deliverable) and PR #1172 (`chore/adr-chart-version-sync-table-rows`,
cycle 2's real deliverable) both merged.

## What's blocked

Unchanged: the same six Now/next ROADMAP items remain gated. Re-checked directly this
cycle:
- Three sequential Forgejo-migration items — each requires a live-cluster session to
  push real repo content / `terraform apply` / verify a real sync, per their own item
  text; a clusterless remote session must not flip these and merely hope.
- The `verifyImages` Enforce flip and the O4 CI-rejection-gate item — both blocked on
  unconfirmed maintainer-confirmation issue #631 (last comment 2026-08-11 13:09 UTC:
  root cause fixed in PR #1114/#1115, but live verification still not observed —
  re-checked, no new comment since).
- The legacy capstone `Deployment` removal — blocked on unconfirmed issue #633 (same
  last-comment timestamp, same status).

No open PRs, no open issues besides the two standing `[Action required]` trackers
above, no `docs/roadmap/incoming/` files, zero un-RFC'd 🟡 items anywhere in
ROADMAP.md.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

Walked the full fallback chain again from the top, distinct from cycles 1–2's own
angles (a real-upstream chart-currency sweep across every `gitops/platform/*.yaml`
pin, then a mechanical-guard extension for ADR-0034's table-row shape):

- **PLANNER** — no ungroomed open issues, no `docs/roadmap/incoming/` files, zero
  un-RFC'd 🟡 items. Nothing to groom or promote.
- **ARCHITECT** — zero open `adr-audit` issues; this week's
  `docs/industry/2026-W33-digest.md` was already refreshed earlier today by a prior
  run's cycle. Re-checked upstream tags for every Terraform-bootstrapped chart
  (`infra/modules/argocd` is the only one) — `argo-cd-10.3.2` is already the newest
  tag on `argoproj/argo-helm`, matching the live pin. Nothing to decide.
- **UPGRADE-DRAFTER** — re-swept every `gitops/platform/*.yaml` chart pin against its
  real upstream git tags (same method as cycle 1, since PR #1171 freed the one-PR WIP
  cap again): cert-manager `1.21.1`, Cilium `1.18.12`, external-secrets `2.9.0`, KEDA
  `2.20.2`, Kiali `2.30.0`, Kyverno `3.8.2`, Longhorn `1.11.3`, Alloy `1.11.1`,
  Pyroscope `2.2.1`, Vault `0.34.0`, Velero `12.1.0`, TiDB Operator `1.6.6`, Harbor
  `1.19.2`, Trivy Operator `0.35.0`, kube-state-metrics `8.3.0` (this run's own PR
  #1171), node-exporter `4.56.1` — every one already the newest stable tag. No gap.
- **DOC-DRIFT-AUTHOR** — `make ci`'s `readme-check`/`lab-ui-check`/dependency-tree
  drift signals are all clean (confirmed directly, no warnings emitted).
- **TRIAGER** — both open issues (#631, #633) already carry a full `domain:*` +
  `readiness:*` + `priority:*` label set. Nothing to triage.
- **JANITOR** — considered one additional candidate distinct from PR #1172's guard:
  `scripts/adr-image-pin-sync-check.sh` only recognizes the "pinned official `<image>`"
  bullet phrasing (RabbitMQ/ADR-0009, Valkey/ADR-0018); ADR-0034's own table also has a
  Tempo row citing a raw image tag inline (`` `deployment.yaml` pins `image:
  grafana/tempo:2.10.7` directly ``, currently accurate — verified directly against
  `gitops/observability/tempo/deployment.yaml`). Decided **not** to build a third
  mechanical-guard shape for it this cycle: unlike the four rows PR #1172 just covered
  (which had *zero* other periodic re-check), Tempo's tag is already actively
  re-verified on its own cadence by ADR-0006's ongoing Grafana/Loki/Tempo CVE-sweep
  Re-evaluation log (most recently 2026-08-06) — a real but materially lower staleness
  risk than the four-row gap just closed. More importantly, the row's own text splits
  the image name across two different table cells (the path fragment
  `gitops/observability/tempo` lives in the "Deployment shape" column, the bare
  filename `deployment.yaml` and the `image:` tag live in "Source") rather than one
  clean self-contained cell like the four rows PR #1172 covers — a mechanical
  extraction here would need to stitch two cells together, a meaningfully more
  fragile regex than the existing checks' single-cell parse, and a wrong extraction
  producing a false-positive drift failure would be a worse outcome than the gap it
  closes (CLAUDE.md: prefer no guard over a fragile one that erodes trust in `make
  ci`). Filing this reasoning here rather than building it, per ROADMAP rule #9's
  "say so... with the actual reasoning" guidance for a genuinely-considered-and-
  declined slice.

## This run's cumulative outcome so far

Two real deliverables landed this run: PR #1171 (kube-state-metrics chart currency
bump, closing the one real upstream-currency gap found across a full `gitops/`
sweep) and PR #1172 (a mechanical recurrence guard for ADR-0034's table-row
self-tracking shape, directly motivated by PR #1171's own hand-edit having nothing
to catch it). This cycle's honest outcome is the third PR-shaped record.

Per STEP 8, the run continues past this point.
