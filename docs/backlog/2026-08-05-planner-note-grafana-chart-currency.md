# Planner note — 2026-08-05 (Grafana chart currency)

## What this run did

Reached the planner role via `executor.prompt.md` STEP 6b: the "Now / next"
lane held only the same 3 items every recent cycle has found gated (on
standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle by reading both issues' comment threads directly: both still open, most
recent comments (2026-08-04) describe an in-progress GitLab Runner setup, no
completed end-to-end confirmation yet). No ungroomed GitHub issues existed to
groom (only the two standing `[Action required]` issues above, which are not
intake). `docs/roadmap/incoming/` held no pending architect items. No later
ROADMAP section (`Heavy on-demand components`, `Capstone`, `Cross-cutting
hardening`) held any un-promoted 🟢 item — everything there is either already
`[x]` or crossed out as `**Groomed ↗**` into *Now / next*.

Per prior cycles' own "chart-pin currency" lens (2026-08-03, 2026-08-04 —
Kiali/Harbor/cert-manager/Kargo/KEDA), this cycle checked a set of components
those cycles hadn't yet covered: Grafana, ArgoCD-notifications, Istio,
tidb-operator, vault-helm, kargo (re-check), external-secrets,
kedacore/keda, grafana/alloy — verified directly against real upstream
sources (`git ls-remote --tags` + full clones for diffing, not training
knowledge, ADR-0004).

## What was found

- **tidb-operator** (`v1.6.5` pinned): newest tag is still `v1.6.5`. No gap.
- **vault-helm** (`v0.34.0` pinned): newest tag is still `v0.34.0`. No gap.
- **kargo** (`v1.11.0` pinned): newest tag is still `v1.11.0`. No gap
  (re-confirms the 2026-08-04 planner note's finding).
- **external-secrets** (`v2.8.0` pinned): newest tag is still `v2.8.0`. No gap.
- **kedacore/keda app** (`v2.20.2`): newest tag is `v2.20.2`, matching this
  lab's `keda.yaml` chart pin (KEDA's chart and app versions track 1:1 as of
  the current release line) — resolves the 2026-08-04 note's open follow-up
  ("KEDA's tag scheme... worth a follow-up sweep"). No gap.
- **Grafana: one real, verified delta.** `gitops/platform/observability-grafana.yaml`'s
  `repoURL` is `https://grafana-community.github.io/helm-charts` — the
  community-maintained fork, since upstream `grafana/helm-charts` is stale
  (its own newest `grafana-*` tag tops out at `10.5.x`, far behind this lab's
  pin — confirms it's the wrong repo, not a real currency signal). A full
  clone of the correct repo, `grafana-community/helm-charts`, shows
  `grafana-12.10.3` as a genuine tag past the pinned `grafana-12.10.2`.
  `git diff grafana-12.10.2 grafana-12.10.3 -- charts/grafana/` touches only
  `Chart.yaml` (`version` + `appVersion` bump) — zero `values.yaml`/template
  changes. The one commit in that range is a routine renovate Docker-tag bump,
  not a CVE fix. Confirmed this doesn't reset or interact with ADR-0006's
  separately-tracked, CVE-driven `image.tag` pin (`13.0.3`, last audited
  2026-07-28, kept) — the chart's own `appVersion` default (`13.1.2`) is
  irrelevant here since this Application overrides `image.tag` explicitly.

Added as a new 🟢 Now/next item (`auto/grafana-chart-12-10-3`) with full
implementation detail, following the same smallest-safe-delta pattern as the
Harbor/cert-manager/Kiali/kro bumps already in `## Done`.

## Why no other action this cycle

The sweep found one real, verified, packaging-only delta — a single
well-scoped ROADMAP item is this cycle's honest deliverable, not manufactured
additional churn. Every other component checked this pass was already
current, closing out the 2026-08-04 note's one open follow-up (KEDA) along
the way.

## What would unblock further Now/next work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633 — PR #980
is the maintainer's own live in-progress work toward that; (b) a new GitHub
issue of any size (ungroomed intake); (c) a new upstream CVE/release firing
one of the tracked ADR flip conditions.

This is this cycle's deliverable, not the run's stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8, which should
pick up the newly-added Grafana item directly.
