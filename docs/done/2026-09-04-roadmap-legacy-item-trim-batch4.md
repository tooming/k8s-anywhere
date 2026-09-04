# ROADMAP.md legacy `[x]` item trim — batch 4

Continuing the pilot batch, batch 2, and batch 3
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md)).

## What was done

Trimmed 5 more legacy items — the O1 Kyverno + cosign + Trivy Operator +
ADR-0017 sequence — each verified against its real `docs/done/` mirror
before touching the ROADMAP text:

- Kyverno engine + observability →
  [docs/done/auto-kyverno-engine.md](auto-kyverno-engine.md) (PR #170)
- Kyverno initial ClusterPolicies (validate + mutate + verifyImages) →
  [docs/done/legacy-kyverno-initial-clusterpolicies-validate-mutate-verifyimages.md](legacy-kyverno-initial-clusterpolicies-validate-mutate-verifyimages.md)
  (PR #177)
- cosign-bootstrap.sh day-0 seam →
  [docs/done/auto-cosign-bootstrap-script.md](auto-cosign-bootstrap-script.md)
  (PR #178)
- Trivy Operator continuous scanning + SBOMs →
  [docs/done/auto-trivy-operator.md](auto-trivy-operator.md) (PR #183)
- ADR-0017 amendment — four Tier 1 next-wave namespace rows →
  [docs/done/2026-06-12-auto-adr-0017-next-wave-rows.md](2026-06-12-auto-adr-0017-next-wave-rows.md)
  (PR #184)

As with batch 3, four of these five `docs/done/` mirrors predate the
`## PR` convention entirely (`auto-*`/`legacy-*` filenames with no date
prefix) and either had no `## PR` section at all, or — in the Kyverno
ClusterPolicies file — a literal `PR #TBD` placeholder that was never
backfilled. Found each real merged PR via GitHub search (all four
confirmed `merged: true`: #170, #177, #178, #183) and added/fixed a
proper `## PR` section in each mirror before pointing ROADMAP.md at it
(ADR-0004 — never propagate an unverifiable placeholder into the trimmed
form). The fifth (`2026-06-12-auto-adr-0017-next-wave-rows.md`) already
had a real link (PR #184), just under the repo's old name
(`tooming/k8s-lab`, which GitHub redirects to the current
`tooming/k8s-anywhere`) — left as-is since it resolves correctly and
touching it would be outside this cycle's bounded scope.

Each item's full inline text replaced with the established short-pointer
format. No information lost — the full detail already lived in the linked
`docs/done/` files (now each with a real PR link too), confirmed
equivalent by reading all five before editing.

## Result

`ROADMAP.md`: 7187 → 7034 lines (153 lines saved from 5 items). ~162
legacy items remain for future bounded cycles to continue against.

No `gitops/` change. `make ci` passes green.

## PR

(filled in after PR creation)
