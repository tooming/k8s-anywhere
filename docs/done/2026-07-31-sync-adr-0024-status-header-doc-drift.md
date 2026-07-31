# Fix stale "manifests pending" Status header in ADR-0024

ADR-0024's own Status paragraph — untouched since its original authoring (PR #302,
2026-06-30) despite two later currency audits of this exact ADR — still said
"Manifests pending — to be groomed from RFC #297 into executor items" and "nothing
here asserts Harbor is deployed or running." Both claims have been false for weeks:

- Harbor's manifests landed the same day the ADR itself was authored
  (`docs/done/2026-06-30-harbor-application.md`).
- The footprint gate this Status paragraph frames as "not a foregone conclusion" was
  measured and passed: `docs/done/2026-07-29-harbor-capstone-rewire.md` records
  ~6.6 GB/12 GB (~55%), "comfortably meeting the ADR-0024 12 GB gate."
- The capstone pipeline was rewired to Harbor
  (`docs/done/2026-07-29-harbor-capstone-rewire.md`), and Artifactory's manifests
  were fully decommissioned (`docs/done/2026-07-29-harbor-artifactory-decommission.md`,
  `tests/no-artifactory.bats`) — Harbor is now the only registry manifest set in the
  repo.

This is an ADR-0004 risk in the opposite direction from the usual case: instead of
asserting something is running that isn't, the ADR was asserting the opposite —
that nothing is running/decided yet — when the real state is verified and shipped.
Both are equally a violation of "never fabricate content presented as the lab's
real state."

## Fix

Rewrote the Status paragraph to state Harbor is live (footprint-verified,
code-complete — it remains on-demand/manual-sync per ADR-0003, so "live" doesn't
mean continuously running), citing the three `docs/done/` entries above and
`tests/no-artifactory.bats` as the verification trail, rather than leaving the
original "pending"/"not asserted" language stale.

No topology/decision change — ADR-0024's actual decision (Harbor over Artifactory)
is unchanged; this is pure status-accuracy reconciliation. Fourth fix in this run's
"cross-check a recent multi-file change against every doc that describes it" sweep.

`make ci` passes (2345 assertions, 0 failures; `markdown-links-check` confirms the
`docs/done/` references resolve).

## PR

(filled in after PR creation)
