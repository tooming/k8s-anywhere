# [Action needed] Now/next still gated; CI-tooling currency sweep clean (cycle 6)

Autonomous scheduled run — the executor's honest STEP 6b fallback record for
this cycle, `executor.prompt.md` STEP 6b, sixth cycle of this run.

## Now / next status

Unchanged from every earlier cycle this run: all three unchecked ROADMAP items
remain gated.

- **`Rename scripts/gitlab-*.sh → scripts/forgejo-*.sh`** — the item's own
  inline investigation note (unchanged) says this needs a genuinely different
  auth mechanism (SSH deploy keys, not HTTPS+PAT) that only a live-cluster
  session can design and verify.
- **`Decommission gitlab/docker-compose.yml + infra/modules/gitlab-config`** —
  deliberately held pending live proof Forgejo is stable "over a real work
  cycle" — a live-cluster observation this clusterless session can't make.
- **`Remove legacy capstone Deployment`** — gated on issue #633 (re-checked
  this cycle: still open, no new comment since 2026-08-17T18:50:01Z).

Issue #1229 (KUBECONFIG secret for the O4 CI rejection-gate job) also
re-checked: still open, unconfirmed.

## What this cycle tried (a fresh angle from cycles 1-5's dependency-register
## focus, per STEP 8's "widen the lens" guidance)

This run's first five cycles all worked the `docs/dependency-register.md`
staleness vein (found + fixed 3 stale rows + a new `make ci` guard + its
PostToolUse hook + an ADR-0034 bold-entry extension — PRs #1297, #1298,
#1299, #1301, #1302). This cycle deliberately tried a different surface
instead of continuing that same vein:

- **GitHub Actions pins** (`.github/workflows/*.yml`): `actions/checkout`
  (pinned SHA `3d3c42e...`), `actions/cache` (`55cc8345...`),
  `actions/github-script` (`3a2844b7...`), `hashicorp/setup-terraform`
  (`dfe3c3f8...`) — all four independently re-verified against their real
  releases pages this cycle. Every pinned SHA matches its action's newest
  published release tag exactly. **No gap.**
- **CI tool pins** (`.github/workflows/ci.yml`): `kubeconform` `v0.8.0`,
  `kustomize` `kustomize/v5.8.1` — both independently re-verified against
  their real releases pages. Both are still the newest published release.
  **No gap.** (`tflint` installs via its own `install_linux.sh` script with no
  version pin — an intentional always-latest choice, not something to check
  for staleness.)
- **ROADMAP.md's "Cross-cutting hardening & quality" filler section** —
  re-read in full: every item is already `[x]` checked or superseded
  (strikethrough, groomed elsewhere); zero unpromoted filler items remain
  anywhere in the file (confirmed: `grep -n '^- \[ \]' ROADMAP.md` finds only
  the same three gated Now/next items above, unchanged all run).

**`make ci`:** green (unchanged from the prior cycle; nothing in this repo
needed a change this cycle).

Going straight back to STEP 1 per STEP 8 — this is not a stopping point.
