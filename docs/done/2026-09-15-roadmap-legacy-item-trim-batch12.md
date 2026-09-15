# ROADMAP.md legacy `[x]` item trim — batch 12

Continuing batches 9–11
([docs/done/2026-09-15-roadmap-legacy-item-trim-batch9.md](2026-09-15-roadmap-legacy-item-trim-batch9.md),
[docs/done/2026-09-15-roadmap-legacy-item-trim-batch10.md](2026-09-15-roadmap-legacy-item-trim-batch10.md),
[docs/done/2026-09-15-roadmap-legacy-item-trim-batch11.md](2026-09-15-roadmap-legacy-item-trim-batch11.md)),
same run. Also used a currency-checking capability found live this cycle
(PR #1625): `raw.githubusercontent.com` and the git wire protocol are
reachable from this sandbox even though `registry.terraform.io`/
`get.helm.sh`/per-repo `api.github.com` calls are not — used it to
directly re-verify every currently-pinned always-on dependency's real
upstream tag: ArgoCD, Traefik, k3s, cert-manager, Terraform, Terragrunt
(bumped, PR #1625), kustomize, kubeconform, and tflint. All except
Terragrunt were already at the latest stable release — no further bump
due this cycle.

## What was done

Re-ran the trim scan against the post-batch-11 `ROADMAP.md`. Only 7
candidates over ~10 lines remained; 4 were deliberately left untouched:
the GitLab→Forgejo rename item (no single clean mirror, same deferral as
every prior batch), the `observability`/Pyroscope item (carries a live,
still-relevant "raw.githubusercontent.com works despite api.github.com
being blocked" operational note — not pure duplication, kept as
forward-looking guidance), the k3s `v1.37.0` item (carries a concrete,
still-unmet flip condition — `v1.37.1+` hasn't shipped yet, re-confirmed
live this cycle — worth keeping visible rather than trimmed away), and the
DORA-metrics-regeneration item (already a single compact paragraph, not
meaningfully duplicated).

Trimmed the 3 remaining confirmed-safe candidates (33 lines saved):

1. **Stale `velero-networkpolicy.yaml` TiDB-removal namespace-list
   comment** →
   [docs/done/2026-09-06-velero-networkpolicy-tidb-comment-fix.md](2026-09-06-velero-networkpolicy-tidb-comment-fix.md)
   (20→4 lines).
2. **`auto-update-prs.yml` concurrency group** →
   [docs/done/2026-09-08-auto-update-prs-concurrency.md](2026-09-08-auto-update-prs-concurrency.md)
   (13→4 lines).
3. **`docs/platform-products.md` stale "6 always-on namespaces" claim** →
   [docs/done/2026-09-08-platform-products-namespace-count-fix.md](2026-09-08-platform-products-namespace-count-fix.md)
   (12→4 lines).

No information lost — every trimmed item's full text already lives
complete in its cited mirror.

## Result

`ROADMAP.md`: 2202 → 2179 lines (33 lines saved from 3 items). This
closes out the "already-`docs/done/`-linked but still duplicated" trim
lens for this run — the file still has ~50 lines of legitimately-kept
duplication (the 4 deliberate exceptions above) plus the still-unresolved
GitLab→Forgejo rename item, but nothing left clears the ~10-line bar
without one of those caveats.

## Validation

`make ci` — full local run, exit code 0. `make roadmap-check` and `make
markdown-links-check` — clean.

No `gitops/` change.

## PR

#1626
