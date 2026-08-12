# [Action needed] Now/next still gated; NetworkPolicy port-mismatch guard investigated, ruled infeasible as a bounded check

**Date:** 2026-08-12
**Cycle:** 3rd cycle this run (after PR #1162 — planner-fallback Q16 concentration-risk
rollup item, PR #1163 — building that item)

## What's blocked

The "Now / next" lane holds six unchecked items, all gated, unchanged since the start
of this run:

1. **Flip `Application` `repoURL`s to the Forgejo remote** — explicit live-cluster-only
   flip; this item's own text states a clusterless remote session must not attempt it.
2. **Rename `scripts/gitlab-*.sh` → `forgejo-*.sh`** — sequentially blocked on item 1.
3. **Decommission `gitlab/docker-compose.yml`** — sequentially blocked on items 1–2.
4. **`verifyImages` ClusterPolicy Audit → Enforce flip** — gated on standing issue
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (re-checked this cycle:
   `updated_at` and comment count unchanged since 2026-08-11, no new confirmation).
5. **O4 CI gate — `verify-image-rejection` job** — sequentially blocked on item 4
   merging first.
6. **Remove legacy capstone `Deployment`** — gated on standing issue
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-checked this cycle:
   `updated_at` and comment count unchanged since 2026-08-11, no new confirmation).

No live-state-safe slice was found to split off any of these (item 1 is itself
already the split-out gated slice from a prior rule-#9 split).

## What was tried this cycle (STEP 6b fallback chain, in order)

- **PLANNER**: no groomable intake (the only two open issues are #631/#633, the
  standing trackers above — not user work requests, both already correctly labeled).
  No un-RFC'd 🟡 item anywhere in ROADMAP.md (verified: zero `- [ ] 🟡` lines). No
  `docs/roadmap/incoming/` file to absorb (dir holds only its `README.md`). Re-swept
  `docs/dora-audit-readiness.md` for any gap not yet closed: Q16 (concentration risk)
  was closed this same run (PR #1163, previous cycle); every other open gap is
  explicitly a *cadence* gap the document itself argues is an acceptable trade-off for
  a solo-operator, on-demand-by-design lab (Q5, Q11, Q13, Q15, Q18) or already-minimal
  priority (Q17 — "minor: exits happen reactively"), not a genuinely new artifact to
  build. `docs/industry/`'s current-week digest (2026-W33) already exists — no gap
  there either.
- **ARCHITECT**: no un-RFC'd 🟡 item to decide (same finding as above).
- **UPGRADE-DRAFTER**: checked upstream currency for Envoy Gateway (`v1.8.3` — latest
  stable, `v1.9.0` is still an RC), External Secrets (`2.9.0` — matches latest
  `helm-chart-2.9.0`), Vault Helm chart (`0.34.0` — matches latest `v0.34.0`), Trivy
  Operator (chart `0.35.0`/appVersion `0.33.0` — matches latest `v0.33.0`), kro
  (`0.9.3` — matches latest `v0.9.3`), Kargo (`1.11.1` — matches latest `v1.11.1`).
  ArgoCD's Terraform-pinned chart (`infra/modules/argocd/variables.tf`, `10.3.2`) not
  independently re-verified against the chart index this cycle (both `argoproj.github.io`
  and `artifacthub.io` are blocked by this environment's egress proxy, and
  `api.github.com` rate-limited unauthenticated `WebFetch` requests partway through this
  sweep) — no actionable bump found among the sources that *were* checkable. Every
  ADR-pinned hold (Valkey, Cilium, Longhorn) was already re-confirmed unfired in the
  immediately preceding cycle's own investigation
  (`docs/done/2026-08-12-dependency-concentration-rollup.md`'s predecessor cycle).
- **DOC-DRIFT-AUTHOR**: `make readme-check` + `make lab-ui-check` both clean (part of
  the local `make ci` run at the top of this cycle). No broken Application source
  paths found.
- **TRIAGER**: both open issues (#631, #633) already carry `domain:*` +
  `readiness:*` + `priority:*` labels — nothing untriaged.
- **JANITOR**: investigated one concrete candidate in depth — a mechanical guard
  against the exact bug class that caused issue #631/#633's longest-lived blocker
  (`allow-harbor-ingress.yaml`'s NetworkPolicy `ports:` value matching the Service's
  *front-door* port, `80`, instead of the destination pod's real `containerPort`,
  `8080` — fixed in a prior live-cluster session, PR #1054, and now correctly `8080`
  on `main`). A generic checker (cross-reference every `NetworkPolicy` ingress
  `ports:` value against the Service `port`/`targetPort` pair it's meant to guard, in
  the same namespace, and flag when the NetworkPolicy value matches the Service's
  front-door port while `targetPort` differs) was ruled infeasible as a *bounded*,
  reliable check: the majority of this repo's components — including Harbor itself,
  the exact component that caused the historical bug — are Helm-templated ArgoCD
  `Application`s with no in-repo `Service` manifest to cross-reference at all (the
  Service is rendered by the chart at apply time, not committed to this git tree). A
  checker scoped only to the minority of plain-manifest components (`data`,
  `inkless`, `moto`, observability internals, RabbitMQ, Valkey, capstone/demo) would
  by construction miss the exact case that motivated it, and a naive one would need to
  resolve `podSelector` labels to their owning Deployment/StatefulSet to find the real
  container port for the Helm-rendered majority — well beyond a single bounded,
  land-green-in-one-sitting cleanup, and risky for false positives against a codebase
  this size (~60 NetworkPolicy files with explicit `ports:` blocks). Confirmed no
  narrower, still-real duplication/dead-code/missing-guard candidate this cycle:
  `grep`'d for TODO/FIXME/XXX across `scripts/`, `gitops/`, `infra/` (zero hits,
  matching the prior cycle's own sweep) and confirmed the one recent comment-drift
  class (stale `gitops/secrets/*-externalsecret.yaml` header comments) was already
  fully swept and closed by a preceding cycle today
  (`docs/done/2026-08-12-harbor-s3-externalsecret-stale-comment-fix.md`).

## What would unblock the standing gates

Unchanged from every prior cycle's note on this: both #631 and #633 need a
live-cluster session with real host headroom to complete a full pipeline run (build →
cosign sign → push to Harbor → Kyverno admission →, for #633, a Kargo promotion).

## What might unblock the next cycle's UPGRADE-DRAFTER pass

This cycle's egress proxy blocked `argoproj.github.io` and `artifacthub.io` outright
and rate-limited unauthenticated `api.github.com` `WebFetch` calls after roughly a
dozen requests in quick succession — a future cycle should space upgrade-currency
checks out, or prefer `index.yaml`/release-API sources not already blocked, rather
than retrying the same blocked domains.

This is a real, honest cycle outcome, not an idle declaration — per STEP 8, the run
continues past this point to the next cycle.
