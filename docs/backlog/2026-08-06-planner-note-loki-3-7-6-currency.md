# Planner note — 2026-08-06 (Loki `3.7.5` → `3.7.6` currency)

## What this run did

Reached the planner role via `executor.prompt.md` STEP 6b: all three
standing "Now / next" items were re-confirmed still gated on the standing
maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — read both
issues' full comment threads directly; the latest comments on each
(2026-08-06 07:38 UTC) describe the same live-cluster blocker (Vault/Harbor
health, host resource ceiling) with no maintainer confirmation posted. No
ungroomed GitHub issues existed to groom (`list_issues` returned only the
three standing `[Action required]` issues — #631, #633, #1034 — none of
which are intake). `docs/roadmap/incoming/` held no pending architect items
(only its `README.md`). No later ROADMAP section (`Heavy on-demand
components`, `Capstone`, `Cross-cutting hardening & quality`) held an
un-promoted 🟢 item — everything there is either already `[x]` or
struck through as `**Groomed ↗**` into *Now / next*.

## What was found

This session's network policy blocks direct HTTPS to almost every Helm
chart-repo host used by this lab's `gitops/` sources (`charts.jetstack.io`,
`prometheus-community.github.io`, `grafana.github.io`, `argo-helm.github.io`,
`helm.goharbor.io`, `kro.run`, etc. all returned a proxy-level 403 policy
denial) — so a full chart-currency sweep like recent prior cycles ran was not
repeatable this cycle. `git` operations against GitHub source repos
(`git ls-remote`/clone) and Docker Hub's public tags API were both reachable,
so the check narrowed to plain `image:` pins with a GitHub-hosted source repo
and a matching Docker Hub image — the same category the just-merged
`3.7.4`→`3.7.5` Loki bump falls into.

Re-checked `grafana/loki` specifically since it was the freshest bump in this
lab's history (merged earlier today). `git ls-remote --tags
github.com/grafana/loki` shows a brand-new `v3.7.6` tag, not present when the
`3.7.5` bump was made — confirmed via Docker Hub's tags API that the
`grafana/loki:3.7.6` image itself is published (multi-arch manifest, pushed
2026-08-06T09:36 UTC, i.e. after this lab's `3.7.5` bump merged). No
`3.7.7`/`3.8.0` exists yet. `git log v3.7.5..v3.7.6` on a real clone shows one
substantive commit past a docs backport: `fix(queryrange): Preserve sketch in
MergeLabels [release-3.7.x]` (#23770), a real query-correctness fix (topk/
sketch merging for detected-labels queries) — no `[SECURITY]` tag this time,
but a verified, real fix on the exact patch line this lab tracks, the same
bar the `3.7.4`→`3.7.5` bump's own non-CVE commit
(`fix(ingester): Fix flush race`) used.

Added as a new 🟢 Now/next item (`auto/loki-3-7-6`) with full implementation
detail (image bump, `tests/observability-loki.bats` assertion flip, a new
ADR-0006 `## Re-evaluation log` entry), following the same
smallest-safe-delta pattern as the Grafana/Harbor/cert-manager/Kiali/kro/KSM
bumps already in `## Done`.

## Why no other action this cycle

The network-policy block on most Helm chart-repo hosts genuinely narrowed
what could be verified this cycle (ADR-0004: not asserting currency on
sources this session couldn't actually reach). One real, verified,
non-security-but-correctness-fix delta was found and added — a single
well-scoped item is this cycle's honest deliverable, not manufactured churn
around the sources this session couldn't check.

## What would unblock further Now/next work

(a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub issue
of any size (ungroomed intake); (c) a future session with broader network
reach re-running the full chart-repo currency sweep prior cycles used
(`charts.jetstack.io`/`prometheus-community.github.io`/etc. were unreachable
this cycle); (d) the still-open ArgoCD Terraform-chart `10.2.2`→`10.2.3`
(appVersion `v3.4.6`→`v3.5.0`) diligence flagged by the 2026-08-05 planner
note (unresolved, not re-attempted this cycle).

This is this cycle's deliverable, not the run's stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8, which should
pick up the newly-added Loki item directly.
