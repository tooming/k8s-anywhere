# ROADMAP.md legacy `[x]` item trim — batch 32

JANITOR-fallback cleanup (STEP 6b), continuing the chain of prior batches:
[batch 15](2026-09-05-roadmap-legacy-item-trim-batch15.md) through
[batch 30](2026-09-06-roadmap-legacy-item-trim-batch30.md), plus the
[partial-trim leftover sweep](2026-09-06-roadmap-partial-trim-leftover-sweep.md)
(a distinct bug class, not numbered as a "batch").

## Why in scope

Re-walked the STEP 6b fallback chain fresh after the leftover-sweep PR
merged (PR #1446): issues #633 and #1229 both remain open/unconfirmed, so
the "Now / next" ROADMAP lane is still fully gated. No open PRs existed
(confirmed via direct GitHub API, after an earlier MCP-tool rate-limit hit
this cycle) and no new issues were filed. JANITOR falls through to the
established ROADMAP.md legacy-item-trim cleanup, back to the standard
"still fully verbose inline" scan (not the leftover-prose bug class fixed
in the prior PR).

## Items trimmed this batch

Each item's full verbose inline text was replaced with a pointer to its
existing `docs/done/*.md` record, after independently re-verifying the
cited PR's `merged: true` state via the GitHub API (ADR-0004):

- **Bump kiali-server chart `1.89.8` → `2.29.0`** — mirror:
  [docs/done/2026-07-23-arch-adr-0012-kiali-chart-index-audit.md](2026-07-23-arch-adr-0012-kiali-chart-index-audit.md)
  — PR #669 (verified `merged: true`).
- **`vault` PSA `baseline` → `restricted` flip** — mirror:
  [docs/done/2026-07-17-vault-psa-restricted.md](2026-07-17-vault-psa-restricted.md)
  — PR #481 (verified `merged: true`).
- **`observability` readOnlyRootFilesystem tighten — Alloy** — mirror:
  [docs/done/2026-07-15-observability-readonlyrootfs-alloy.md](2026-07-15-observability-readonlyrootfs-alloy.md)
  — PR #413 (verified `merged: true`).
- **`observability` readOnlyRootFilesystem tighten — Grafana** — mirror:
  [docs/done/2026-07-15-observability-readonlyrootfs-grafana.md](2026-07-15-observability-readonlyrootfs-grafana.md)
  — PR #414 (verified `merged: true`).
- **Trivy Operator dashboard** — mirror:
  [docs/done/2026-06-15-trivy-dashboard.md](2026-06-15-trivy-dashboard.md).
  The mirror cited no PR at all; found the real PR via `search_pull_requests`
  on the branch name (`auto/trivy-dashboard`) → PR #212 (verified
  `merged: true`).

## Deliberately left alone

**"Flip `Application` `repoURL`s (including `root-app.yaml`) to the Forgejo
remote, verify a real sync"** (PR #1205) — a live-cluster session record with
no `docs/done/*.md` mirror at all (live-cluster interactive sessions don't
always produce one). Consistent with batch 6's own precedent for this exact
item: left as a candidate for a future cycle willing to author a proper
mirror first, rather than inventing one this cycle didn't verify end-to-end.

## Verification

- `wc -l ROADMAP.md` — 2089 lines (down from 2166 before this batch).
- `make ci` — full local suite green, including `docs-done-pr-link-check`
  and `roadmap-check`.

## PR

(placeholder — backfilled after `create_pull_request` returns)
