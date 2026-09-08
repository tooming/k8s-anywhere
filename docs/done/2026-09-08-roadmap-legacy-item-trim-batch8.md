# ROADMAP.md legacy `[x]` item trim — batch 8

Continuing batch 7
([docs/done/2026-09-08-roadmap-legacy-item-trim-batch7.md](2026-09-08-roadmap-legacy-item-trim-batch7.md)),
cycle 23 of this autonomous run. Batch 7 deliberately left two candidates
untrimmed because resolving their real `docs/done/` mirror needed more
careful reading than that cycle had budget for. This batch does that
reading and resolves both:

- **"Namespace Resource Profiles — LimitRange defaults fan-out"** — batch
  7's search for a mirror named after the branch (`auto/namespace-resource-
  profiles`) found nothing (no `docs/done/` file references that branch
  name in its text), and several similarly-titled
  `docs/done/governance-limitrange-*.md` files turned out to be *later*
  janitor consolidation/fix work (PR #319's shared-base-file refactor and
  its own follow-up path-bug fix), not this original build item. The real
  mirror is
  [docs/done/2026-06-30-namespace-resource-profiles.md](2026-06-30-namespace-resource-profiles.md)
  (PR #304) — found by grepping for "RFC #294" instead of the branch name.
  Read in full and confirmed word-for-word identical scope (same 18
  standard-tier namespaces, same heavy-tier `observability` profile, same
  ADR-0024 `artifactory`-omission deviation) before trimming.
- **"Decommission Artifactory manifests"** — confirmed
  [docs/done/2026-07-29-harbor-artifactory-decommission.md](2026-07-29-harbor-artifactory-decommission.md)
  (PR #887) is in fact the exact, complete mirror for this item (its own
  first paragraph is a verbatim copy of the ROADMAP item's spec) — batch
  7's caution about "broader scope than just this ROADMAP item" doesn't
  hold up on a full read: the extra "fixed in passing" section documents
  incidental drift fixes discovered while doing this exact work, not a
  separate unrelated item bundled in. Trimmed with the real PR number
  (#887) and branch name (`auto/harbor-artifactory-decommission`,
  matching the mirror's own citation) rather than the ROADMAP item's
  original placeholder-style branch guess.

## Result

`ROADMAP.md`: 2526 → 2502 lines (24 lines saved from 2 items). No
information lost — both mirrors confirmed fully equivalent to their
ROADMAP items before trimming.

Combined with batch 7, this run has now resolved every candidate its
fixed scan heuristic (require a real `](docs/done/...)` link, not a bare
substring match) surfaced. A future cycle widening the search further
would need a new heuristic — e.g. items that DO have a `docs/done/` link
already but still carry substantial inline duplication alongside it
(batch 6's original "widen the search" suggestion), which this run has
not yet attempted.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green).

No `gitops/` change.

## PR

[#1536](https://github.com/tooming/k8s-anywhere/pull/1536) (autonomous
scheduled executor run, cycle 23 — resolving batch 7's own deferred
candidates).
