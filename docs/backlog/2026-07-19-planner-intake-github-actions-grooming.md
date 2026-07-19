# Planner run — 2026-07-19 (executor fallback, intake grooming)

## Trigger

Cycle 10 of an ongoing autonomous executor run. Earlier cycles this run
(upgrade-drafter fallback) surfaced real major-version bumps available for
four GitHub Actions used across `.github/workflows/*.yml`
(`actions/checkout`, `actions/cache`, `actions/github-script`,
`hashicorp/setup-terraform`) and filed them as issue #608, per
upgrade-drafter's own rule that same-source *major* bumps need a human/
architect look rather than an auto-built PR (a bad bump here risks breaking
the CI gate itself, the backbone of this repo's self-merge governance
model). A related, safe, zero-behavior-change slice — SHA-pinning the
*currently in-use* versions instead of leaving them on floating major tags —
was built and merged directly the same cycle (PR #609), since it carried no
runner-compatibility risk.

## Intake grooming

Issue #608 is a real, size-appropriate work request (per ROADMAP's "How you
add work" — ungroomed work of unknown size goes through the planner). Sized
it as a single item, tagged 🟡 (needs an architect decision, not a permission
gate): the open question is whether GitHub-hosted `ubuntu-latest` runners'
bundled Node.js version supports the Node ≥24 requirement all four newer
action majors declare — this is runner-software-level information this
clusterless sandbox could not independently verify (no reliable way to query
GitHub Actions' current runner image contents from here), and each action's
own migration notes for the specific major version(s) crossed still need a
careful read before a same-source bump is safe to build. This is exactly
ROADMAP's readiness-tag distinction: not a permission boundary, a genuinely
open technical question.

## Item added to ROADMAP.md ("Cross-cutting hardening & quality")

- **GitHub Actions major-version bumps** — placed as a 🟡 item (not Now/next,
  since Now/next holds only 🟢 items) with the specific decision an RFC (or a
  verified same-run decision) needs to resolve, and a pointer to PR #609's
  SHA-pinned lines as exactly where the eventual bump lands.

## Closing the loop

- Commented on issue #608 linking this ROADMAP item, added the `groomed`
  label, and closed it (its content is now tracked in ROADMAP.md, not the
  issue).

## Not groomed / no action

- No other open GitHub issues at time of this run.
- No pending `docs/roadmap/incoming/` architect items to absorb.
