# ROADMAP.md legacy `[x]` item trim — batch 2

Continuing the pilot batch from the previous cycle
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md)).

## What was done

Trimmed 4 more legacy items, each verified against its real `docs/done/`
mirror before touching the ROADMAP text:

- Extract shared `ok()`/`bad()` helpers to `scripts/lib/colors.sh` →
  [docs/done/2026-08-03-ok-bad-lib-extract.md](2026-08-03-ok-bad-lib-extract.md)
  (PR #960)
- `capstone-pipeline` governance LimitRange (RFC #294) →
  [docs/done/2026-07-26-governance-capstone-pipeline-limitrange.md](2026-07-26-governance-capstone-pipeline-limitrange.md)
  (PR #752)
- O5 bats gap — `lab-argocd.json` + `lab-gitsync.json` →
  [docs/done/2026-07-11-o5-argocd-gitsync-coverage-bats.md](2026-07-11-o5-argocd-gitsync-coverage-bats.md)
  (PR #361)
- Governance gap — `envoy-gateway-system` + `node-exporter` →
  [docs/done/2026-07-11-auto-governance-envoy-node-exporter.md](2026-07-11-auto-governance-envoy-node-exporter.md)
  (PR #362)

Each item's full inline text replaced with the established short-pointer
format. No information lost — the full detail lives in the linked
`docs/done/` files, confirmed equivalent by reading all four before editing.

## Result

`ROADMAP.md`: 7351 → 7297 lines (54 lines saved from 4 items). ~172 legacy
items remain for future bounded cycles to continue against.

No `gitops/` change. `make ci` passes green (2976/2976 bats tests).

## PR

(filled in after PR creation)
