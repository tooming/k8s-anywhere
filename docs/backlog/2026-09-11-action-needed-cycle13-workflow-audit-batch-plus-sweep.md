# [Action needed] Cycle 13 — Workflow-audit batch shipped, renewed sweep exhausted

Cycle 12's own record (this same day) concluded the fallback chain was "genuinely
exhausted" after eleven merged PRs, found via sequential stale-reference sweeps. This
cycle used a different method — a parallel, multi-lens, adversarially-verified
Workflow audit (per this session's Ultracode opt-in) — and it found real work cycle
12's sequential approach had missed: **16 additional real findings**, delivered as
**13 more merged PRs**,
[PR #1559](https://github.com/tooming/k8s-anywhere/pull/1559) through
[PR #1571](https://github.com/tooming/k8s-anywhere/pull/1571):

- 5 doc-drift fixes (stale removed-component references in `docs/platform-products.md`,
  `docs/dora-audit-readiness.md`, `docs/incident-log.md`, `CHARTER.md`, and
  `routines/triager.prompt.md`)
- 1 ADR-convention fix (ADR-0006's superseded-status strikethrough + ADR-0039 index
  annotation)
- 1 governance-doc fix (`WAYS-OF-WORKING.md` §5's incomplete cadence hand-off history)
- 1 stale-figure fix (`ROADMAP.md` rule #4 + `scripts/ondemand-budget-check.sh`'s
  ~7 GB baseline)
- 1 full routine-prompt coherence pass (`routines/verifier.prompt.md` — updated for
  the self-merge model, not just the two originally-flagged findings)
- 1 mechanical-guard fix (`scripts/lint.sh`'s shellcheck glob silently excluded
  `scripts/lib/*.sh` — 8 of 9 files had no shebang, one had a real SC2034; fixed with
  new regression bats coverage per CLAUDE.md's every-bugfix-needs-a-guard rule)
- 2 live-verified dependency bumps (cert-manager `1.21.1`→`1.21.2`, two real
  security fixes; ArgoCD chart `10.8.4`→`10.9.0`, packaging-only)
- 1 fresh dependency-currency re-check (Traefik/k3s, flip condition re-verified live,
  still unmet)

## What this cycle's renewed sweep checked (after the batch above)

- **ROADMAP.md:** zero unchecked `[ ]` items anywhere in the file (`grep '^- \[ \]'`
  — no matches). No un-RFC'd 🟡 items (`grep '🟡'` excluding struck-through/groomed
  entries — no matches). `docs/roadmap/incoming/` empty.
- **Dependency currency:** every `docs/dependency-register.md` row re-sorted by
  "Last reviewed" after the batch above — oldest is Cilium/Oracle at 2026-09-07
  (Cilium is a removed component, nothing live to re-check; Oracle was re-checked
  4 days ago and is a pricing/tier row, not a version pin). k3s (2026-09-09) was
  independently re-confirmed current as part of this cycle's own Traefik sweep
  (`v1.36.4+k3s1` still newest stable, `v1.37.0` only at `-rc5`).
- **Untested scripts:** every `scripts/*.sh` file is referenced by name in at least
  one `tests/*.bats` file (checked directly, zero misses) — mirrors the mechanical
  check already added for `scripts/lib/*.sh` this same cycle.
- **TODO/FIXME markers:** zero unresolved `TODO`/`FIXME`/`XXX:` comments anywhere in
  `scripts/`, `docs/*.md`, `CHARTER.md`, or `ROADMAP.md` (excluding the historical
  `docs/backlog/`/`docs/done/`/`docs/roadmap/investigations/` records, which are
  meant to stay as-written).
- **GitHub issue triage (planner fallback):** blocked this cycle — `list_issues`
  returned "API rate limit already exceeded" on every retry (PR-write tools
  continued to work throughout, so this is scoped to the issues/search quota
  specifically, not a full outage). Genuinely untried this cycle, not confirmed
  empty — flagged honestly rather than asserting a check that didn't happen.

## Assessment

Today's total is now **27 merged PRs** (`git log` main, today's date) — cycle 12's
eleven plus this cycle's thirteen plus cycle 12's and this cycle's own two
`[Action needed]` records. This is a very high volume for one day, squarely the
scenario WAYS-OF-WORKING.md §5 cautions about ("if output ever outpaces what's
reasonable to spot-check... not silently tolerating it"). Every PR was individually
CI-green, self-reviewed against a concrete, verified finding, and scoped to one
item — but the aggregate volume is real and worth surfacing plainly rather than
quietly continuing to manufacture more.

## What would open new work

- GitHub issue triage, once the API rate limit clears — untried this cycle, not
  confirmed empty.
- A new upstream release, GHSA, or GitHub issue against any pinned source.
- A new GitHub issue opened by the maintainer.
- A live-cluster session exercising `make dr-chaos-argocd`, the k3s datastore
  compactor investigation, or verifying today's two dependency bumps
  (cert-manager, ArgoCD chart) actually apply cleanly on a real cluster.
- The next scheduled firing of this routine, which will re-run this same fallback
  chain — including the issue-triage lane this cycle couldn't reach — against
  whatever has changed by then.

This is cycle 13's honest record, per `executor.prompt.md` STEP 6b's last resort.
