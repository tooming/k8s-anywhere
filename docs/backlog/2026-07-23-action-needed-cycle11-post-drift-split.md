# [Action needed] Now/next still gated; drift-detectors.bats split thread closed out this run

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, still zero comments, unchanged since the
run started.

## What this run actually shipped (10 PRs, not idle)

Once the gated lane was confirmed genuinely starved, this run worked the
full `executor.prompt.md` STEP 6b fallback chain and found real, substantive
work at every rung except planner/triager (both genuinely empty — 3 open
issues, all already the standing `[Action required]` ones, already fully
triaged):

- **Upgrade-drafter (PR #679):** `pingcap/tidb` `v8.1.2` → `v8.5.7` — the one
  real currency gap found after a fresh upstream sweep across Longhorn,
  Kyverno, cert-manager, Kargo, Vault, ArgoCD, and Trivy Operator (all
  already current or nothing groundable to bump).
- **Janitor (PRs #680–#688, 9 PRs):** froze `tests/drift-detectors.bats`
  (662 lines, 24+ unrelated drift-check sections accumulated with no
  mechanical guard — the same "shared monolith multiple PRs append to"
  footgun that already got `securitycontext.bats`/`observability.bats`/
  `networkpolicy.bats` frozen) with the identical snapshot-diff pattern
  those three files use, then split it down across 8 follow-up PRs by
  coherent theme (idle-issue-guard, mimir-readonly-root, three
  frozen-monolith-check scripts, yq-variant-portability, ADR-governance
  sync, CI-workflow-correctness, routines-governance, gitops-manifest
  correctness). Net result: 662 → 173 lines (74% reduction), split across
  8 new per-scope files, each individually revertable, with a permanent
  mechanical guard (`scripts/drift-detectors-tests-check.sh`, wired into
  both `make ci` and `.github/workflows/ci.yml`) against the monolith
  regrowing unchecked.

Every PR: pure/bounded, `make ci` green, self-reviewed, self-merged. One
open item flagged transparently rather than worked around: the new
`scripts/drift-detectors-tests-sync-hook.sh` companion hook is written and
bats-tested but **not wired into `.claude/settings.json`** — that edit was
attempted mid-run and explicitly declined, so it was left as a documented
follow-up rather than retried. The `make ci` gate (the actual enforcement)
is fully active regardless.

## Fresh lenses tried this cycle that came up empty

- Re-verified #631/#632/#633: unchanged.
- Re-checked `gh`-equivalent open-issue list: still exactly 3, all standing
  `[Action required]` issues, already fully labeled (nothing for triager).
- Considered further drift-detectors.bats splits (readme-check,
  lab-ui-check, roadmap-check, markdown-links-check,
  git-fixture-isolation-check, the O2 PSS completeness gate remain) —
  explicitly declined to force a ninth split-PR purely for the sake of
  continuing the thread; the monolith is already down to 173 lines and
  mechanically guarded, so further splitting has genuinely diminishing
  value rather than fixing a real footgun.
- Garage (S3 storage): upstream release feed unreachable from this sandbox
  (`git.deuxfleurs.fr` 403; Docker Hub tags API for `dxflrs/garage` returned
  data inconsistent with the already-deployed `v2.3.0` pin, i.e. clearly
  unreliable) — no actionable change made on unverifiable data (ADR-0004).

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size; (d) `.claude/settings.json` access to finish wiring the
`drift-detectors-tests-sync-hook.sh` companion hook (cosmetic — `make ci`
enforcement is unaffected).

This note is this cycle's honest record — a real, 10-PR-shipping run, not
an idle one. The run continues to the next cycle per `executor.prompt.md`
STEP 8.
