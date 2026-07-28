# [Action needed] Now/next still gated; found + filed one genuinely new lead (argo-cd chart 9.x→10.x)

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles today)

PR #769, #771, #775, #777, #779, #780 (see those PRs' bodies) — an
exhaustive CVE/currency sweep across every actively version-pinned ADR,
plus KRO/TiDB Operator/`ack-s3` (components with no dedicated ADR).

## This cycle's fresh angle

Rather than re-running another CVE sweep (already done to exhaustion this
run and in the two prior days — see `docs/backlog/2026-07-26-*` and
`2026-07-27-*`), this cycle tried three different lenses:

1. **Full local `make ci`** — ran the whole gate (not just the doc-drift
   subset prior cycles spot-checked): lint, README/lab-ui/markdown-link
   checks, the ADR chart-version/image-pin sync checks, the routines-apply
   drift guard, the frozen-file guards — all green. Nothing newly broken.
2. **Fresh intake check** — `is:issue created:>2026-07-27` returned 6 issues,
   all already closed same-run (adr-audit issues from earlier today's
   cycles). No open, ungroomed intake.
3. **Stale-TODO sweep** — grepped the repo for `TODO`/`FIXME`/`XXX` outside
   `docs/done/` (a lens not used by any of the ~28 prior cycles' notes,
   which focused on CVEs/currency/drift). Found two, both already
   deliberately tracked:
   - `gitops/kyverno/policies/disallow-latest-tag.yaml` — references the
     ArgoCD `latest`-tag carve-out below, not a loose end of its own.
   - `infra/modules/argocd/values.yaml`'s `global.image.tag: latest`
     override, with its own TODO: "drop this override once argo-cd chart >=
     the version that ships the expose-appset-ui commit (#26666)."
     Investigated whether this has become actionable: fetched
     `argoproj/argo-helm`'s real `Chart.yaml` at `main` — still
     `appVersion: v3.4.5`, and public sources confirm the ApplicationSet UI
     (upstream PR #26666) ships in ArgoCD **v3.5**, not yet in any stable
     chart release. TODO correctly still not actionable — no change.

   That investigation surfaced a **genuinely new, previously-untracked
   fact**: the `argo-cd` chart's own version line moved from `9.x` (this
   repo's current pin, `9.7.1`) to `10.x` since the last bump landed
   (2026-07-23, `docs/done/2026-07-23-argocd-chart-bump-9-5-20-to-9-7-1.md`).
   Confirmed via `argo-cd-10.0.0`'s real `Chart.yaml`: `appVersion: v3.4.4`
   — identical to our current pin's app version, so no security/currency
   urgency — but per the upgrade-drafter routine's own rule ("skip major
   bumps — open an issue"), a major chart-line crossing is an architect
   decision, not an auto-bump, and no issue for it existed yet (searched
   first). Filed **[#781](https://github.com/tooming/k8s-anywhere/issues/781)**
   with the full verification trail (including the one confirmed breaking
   change in `10.0.0` — removal of `server.additionalApplications`/
   `additionalProjects`, which this repo's `values.yaml` doesn't use) and a
   concrete next step (a Velero-RFC-#617-style values-schema audit) for
   whoever picks it up.

4. **HashiCorp Vault's three 2026 CVEs** (CVE-2026-5807, CVE-2026-5052,
   CVE-2026-3605) — re-verified directly against this run's own fresh web
   search: all three fixed at Vault `2.0.0`; this lab's pin (`2.0.3`, per
   `gitops/platform/vault.yaml`) is past that floor. Same conclusion already
   on record in `docs/backlog/2026-07-26-action-needed-cve-sweep-clean.md`
   and the pin's own Re-evaluation-log comment (2026-07-24) — re-confirmed,
   not a new finding, noted here only because it was part of this cycle's
   verification pass.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) an architect
decision on the new argo-cd chart major-line issue (#781); (c) a new
upstream CVE/release firing a tracked ADR flip condition; (d) a new GitHub
issue of any size.

This note is this cycle's honest record — it produced one real, previously
undiscovered, filed issue (#781), not just a re-confirmation — but is not a
stopping point. The run continues to the next cycle per
`executor.prompt.md` STEP 8.
