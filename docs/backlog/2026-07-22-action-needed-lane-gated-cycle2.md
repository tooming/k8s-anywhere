# [Action needed] Now/next still gated; alloy chart bump correctly held back (no security rationale, real breaking changes)

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle, all three still open, still zero comments.

## This cycle's fresh angle

The prior cycle's record
(`docs/backlog/2026-07-22-action-needed-lane-gated-post-valkey.md`) left one
untried candidate from this session's original chart sweep: `alloy`
(`gitops/platform/observability-alloy.yaml`, chart `alloy` from
`https://grafana.github.io/helm-charts`), pinned at `1.10.1`, with `1.11.0`
available as the next minor.

Checked `1.11.0`'s real release notes
(`github.com/grafana/alloy/releases/tag/v1.11.0`) before bumping, following
this session's established practice of verifying schema/behavior impact
first. Unlike the pyroscope and grafana chart bumps landed earlier this
session (both pure chart-templating maintenance releases with the app
binary unaffected), `alloy`'s chart version tracks its app version 1:1, and
`1.11.0` bundles a **major** internal Prometheus upgrade (v2.55.1 →
v3.4.2) with documented breaking changes to query semantics: PromQL regex
matchers now match newlines, `le`/`quantile` label values are normalized
on ingestion (can break queries referencing integer label values like
`le="1"`), `scrape_native_histograms` defaults change, plus an OpenTelemetry
Collector upgrade (v0.128.0 → v0.134.0) with removed arguments. No CVE or
security fix is mentioned anywhere in the release notes. Alloy is the
collector for this repo's entire always-on LGTMP observability stack, so a
regression here has the widest blast radius of any component in the repo.

**Decision: hold the pin at `1.10.1`.** This mirrors the exact reasoning
this repo already established for the Valkey `8.1.0` release (ADR-0018
audit #627, 2026-07-20): "Bumping a pin with no security or critical-bug
rationale — only 'a newer minor exists' — would be pure churn," and here
the calculus is even clearer since the candidate version carries
*documented breaking changes* on top of having no security motivation.
Confirmed via the GitHub releases listing that no `1.10.x` patch exists
between `1.10.1` and `1.11.0` to take instead. Not landing a PR for this is
the correct outcome, not a missed opportunity — mirrors CLAUDE.md's "never
fabricate make-work" and ROADMAP rule #9.

## Other lenses (already exhausted this cycle per the prior record)

Planner, triager, doc-drift-author, and janitor were all swept in the
immediately preceding cycle (`...-post-valkey.md`) and came up clean or
correctly judged non-actionable (a cosmetic missing +x bit on
`git-fixture-isolation-check.sh` with zero functional effect). Not
re-running those identical checks again this cycle.

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631, #632, or #633; (b) a new upstream CVE/release firing a tracked flip
condition (including, now, a future Alloy security release that would
justify revisiting the `1.11.0`+ hold); (c) a new GitHub issue of any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
