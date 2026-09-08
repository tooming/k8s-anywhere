# ROADMAP.md legacy `[x]` item trim — batch 7

Continuing the pilot batch through batch 6
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md)
through
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md)).
Picked up in cycle 22 of this autonomous run from batch 6's own note that
~154 legacy items remained — a fresh scan was needed since the file has
shrunk considerably since batch 6 (6899 → 2604 lines, mostly from the
2026-09-06/07 component-removal wave deleting whole sections outright
rather than trimming them).

## What was done

Re-scanned for `[x]` items with a long, fully-inline planner build-spec and
no real `](docs/done/...)` pointer link (batch 6's heuristic literally
matched the substring `docs/done/` anywhere in the item text, which
produced false positives on items that only say "`docs/done/` entry
required" in prose without an actual link — this batch's scan fixed that
by requiring the markdown link syntax). Found and verified 5 candidates,
each checked against its real `docs/done/` mirror (confirming the mirror's
content substantively or verbatim matches the ROADMAP item) before
trimming:

- PSS-baseline hardening — `envoy-gateway-system` namespace →
  [docs/done/2026-06-20-pss-envoy-gateway-system.md](2026-06-20-pss-envoy-gateway-system.md)
  (PR #239)
- NetworkPolicy fan-out — `external-secrets` namespace →
  [docs/done/2026-06-21-networkpolicy-external-secrets.md](2026-06-21-networkpolicy-external-secrets.md)
  (mirror predates the "## PR" convention — out of scope for
  `docs-done-pr-link-check.sh` by design, same as several mirrors batch 6
  linked)
- Lab — s3manager (S3 bucket browser) dashboard →
  [docs/done/2026-06-22-s3manager-dashboard.md](2026-06-22-s3manager-dashboard.md)
  (same pre-convention shape — inline `**PR:** auto/s3manager-dashboard`,
  not a `## PR` heading)
- Platform Governance appset — `gitops/governance/` structure +
  ApplicationSet →
  [docs/done/2026-06-30-auto-platform-governance-appset.md](2026-06-30-auto-platform-governance-appset.md)
  (PR #303 — verbatim-duplicate mirror)
- Harbor NetworkPolicy floor + appset entry →
  [docs/done/2026-06-30-harbor-networkpolicy.md](2026-06-30-harbor-networkpolicy.md)
  (PR #307 — verbatim-duplicate mirror)

All five describe components/namespaces since removed entirely
(envoy-gateway-system/ADR-0040, external-secrets/ADR-0042, the
s3manager+Grafana observability pairing/ADR-0041, Harbor/ADR-0024) —
purely historical record now, same status as every other already-`[x]`
legacy item this cleanup targets.

Two more candidates surfaced by the same scan were deliberately **not**
trimmed this batch (kept for a future cycle, consistent with batch 6's own
precedent of leaving imperfect fits alone):

- **"Namespace Resource Profiles — LimitRange defaults fan-out"** — has
  multiple similarly-named `docs/done/governance-limitrange-*` candidate
  mirrors (`2026-07-02-governance-limitrange-base.md`,
  `2026-07-07-governance-limitrange-base-path.md`, and others); resolving
  which one is the *specific* item's real mirror (versus a related
  follow-up PR) needs more careful reading than this cycle had budget for.
- **"Decommission Artifactory manifests"** — its
  `docs/done/2026-07-29-harbor-artifactory-decommission.md` candidate
  mirror covers a broader decommission than just this one ROADMAP item's
  scope (it also covers other cleanup done in the same PR); linking it
  needs confirming the mirror's scope precisely matches before trimming.

Each trimmed item's full inline text replaced with the established
short-pointer format. No information lost — the full detail already lived
in the linked `docs/done/` files, confirmed equivalent by reading all five
before editing.

## Result

`ROADMAP.md`: 2604 → 2526 lines (78 lines saved from 5 items).

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green, including
`markdown-links-check` for the 5 new cross-references this batch adds).

No `gitops/` change.

## PR

[#1535](https://github.com/tooming/k8s-anywhere/pull/1535) (autonomous
scheduled executor run, cycle 22 — picking up batch 6's own documented
follow-up work).
