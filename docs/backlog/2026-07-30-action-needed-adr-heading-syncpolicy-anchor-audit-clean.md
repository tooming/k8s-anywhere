# [Action needed] Now/next still gated; ADR-heading/syncPolicy/anchor-link audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did

Three real merged PRs so far this run:
[#903](https://github.com/tooming/k8s-anywhere/pull/903) (kustomize orphan-file
guard) and [#905](https://github.com/tooming/k8s-anywhere/pull/905) (missing
bats coverage for `tidb-demo.json`), plus three prior cycles' honest records
([#904](https://github.com/tooming/k8s-anywhere/pull/904),
[#906](https://github.com/tooming/k8s-anywhere/pull/906),
[#907](https://github.com/tooming/k8s-anywhere/pull/907)).

## This cycle's fresh angles (all clean)

1. **ADR filename-vs-heading number mismatch.** Cross-checked all 30
   `docs/decisions/adr-*.md` files: the number in each filename against its
   own `# ADR-NNNN` heading. Zero mismatches.
2. **Widened `` `make <target>` `` reference check** beyond the existing
   guard's scope (README.md + `docs/decisions/*.md` only, per
   `scripts/readme-check.sh`). Scanned README.md, CLAUDE.md, ROADMAP.md, and
   every `docs/*.md` file — 59 unique mentions found, 2 don't resolve to a
   live target (`artifactory-up`, `dr-chaos`). Both are intentional: the
   first only appears inside already-`[x]`-checked historical ROADMAP.md
   records (one of which explicitly documents *removing* that target); the
   second is explicitly framed in `docs/dora-audit-readiness.md:163` as "a
   reasonable, scoped **future** ROADMAP item," not a claim of an existing
   target. No drift — the existing guard's narrower scope remains correct.
3. **Grafana dashboard JSON structural audit** — parsed all 29
   `grafana/dashboards/*.json` for duplicate panel `id`s within a dashboard,
   `gridPos` rectangle overlaps between sibling panels, and panels with
   `targets` but no `datasource`. Clean on all three.
4. **ArgoCD `syncPolicy` consistency audit** — parsed all 80 `Application`
   manifests for `selfHeal`/`prune` set independently, and `automated` sync
   without `CreateNamespace=true`. Found 9 `-extras` companion Applications
   in the second category; manually verified each is a deliberate pattern
   (equal-or-later sync-wave than its main Application, which already
   creates the namespace, with explicit in-file comments) — not a
   contradiction.
5. **Markdown same-file anchor-fragment link audit** — implemented GitHub's
   real heading-slug algorithm and checked all 13 in-repo `#fragment` links
   against real headings. One initial false positive
   (`docs/decisions/adr-0016-default-deny-networkpolicy.md:209`'s
   `#scope--exceptions` linking `## Scope & exceptions`) turned out to be
   correct once verified against GitHub's actual (non-collapsing) slug
   algorithm. Clean.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing a tracked ADR flip condition.

This note is this cycle's honest record — five fresh angles tried (via a
background research pass, cross-checked against ~25 prior sweep files to
avoid repeating any of them), all clean. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
