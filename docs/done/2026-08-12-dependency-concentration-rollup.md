# Third-party dependency concentration-risk rollup — closes DORA audit Q16's named gap

(CHARTER **Core Values** §"Everything as code; GitOps deploys it" / operational-resilience
discipline; planner-fallback gap analysis 2026-08-12, reached via `executor.prompt.md`
STEP 6b PLANNER role after this run's Now/next lane was re-confirmed fully gated — the
same six standing items (three sequential Forgejo-migration items; `verifyImages`
Enforce-flip + O4 CI gate on unconfirmed issue #631; capstone `Deployment` removal on
unconfirmed issue #633, both re-checked this cycle, most recent comment 2026-08-11 on
each, neither confirms the gate) — and this cycle's own sweep found no groomable
intake (the only two open issues are those same standing `[Action required]`
trackers), no un-RFC'd 🟡 item anywhere in ROADMAP.md (zero `- [ ] 🟡` lines), and no
`docs/roadmap/incoming/` file to absorb. **No prerequisites — executor may pick up
immediately.**) Verified directly (not assumed, ADR-0004): `docs/dora-audit-readiness.md`
Q16 ("Is concentration risk assessed — reliance on a single upstream provider?")
answered that concentration is "assessed per-decision... but never rolled up into a
single cross-cutting view of *which* single upstream repo, registry, or chart source,
if it disappeared, would break the most components at once," and its own Gap line
called this "real; a genuinely new artifact, not just re-indexing" (distinct from
Q14's `docs/dependency-register.md`, which the register's own header explicitly scopes
as pure re-indexing with "no new dependency-risk judgment"). Grepping `docs/` for
"concentration" turned up only this Q16 answer itself — nothing already tracked this.

Added `docs/dependency-concentration.md`: groups every row of
`docs/dependency-register.md`'s 32-tool table by **upstream GitHub org** (the
register's own "Upstream source" column, reused verbatim — nothing re-derived from
memory) and surfaces any org backing more than one tool as a concentration point, one
short paragraph each, worst-first. The count was verified directly against the live
register table (`grep -c "^| "`, 32 data rows) and cross-checked programmatically
(script parsed the table and grouped by every `github.com/<org>/` match in the
"Upstream source" column) before writing the file — not reused from a stale Q14
number.

## Findings

- **`github.com/grafana` — 6 tools, the largest single concentration in the table:**
  Grafana, Mimir, Loki, Tempo, Pyroscope, Alloy. All six are `always-on-core` — the
  entire observability pane shares one upstream governance/maintenance entity.
- **`github.com/argoproj` — 2 tools:** ArgoCD, Argo Rollouts.
- **`github.com/pingcap` — 2 tools:** TiDB Operator, TiDB (both `heavy-on-demand`
  only, lower blast radius than the always-on groups above).
- Every other row (26 of 32) is a distinct org — stated plainly rather than padding
  the doc with 24 one-line "groups" of a single tool each.

The file closes with the lab's actual, already-true mitigation (not a new one
invented for this file): every workload is a GitOps `Application` pointing at a
pinned chart/image ref (ADR-0001), so a disappeared upstream is a
fork-and-repoint operation, not a rebuild — demonstrated for real by the
ADR-0011→ADR-0024 Artifactory→Harbor migration (the same precedent Q17 already
cites for exit strategy).

## Doc updates

- `docs/dora-audit-readiness.md` Q16's Answer/Evidence/Gap rewritten to point at the
  new file and state the computed findings, replacing the prior "never rolled up"
  gap statement.
- `docs/dependency-register.md`'s "Keeping this in sync" section notes the new file
  is a downstream consumer of its table.
- `tests/dora-audit-readiness.bats` (existing file from the Q2 stateless-criticality
  item — extended, not duplicated, matching this repo's per-topic bats convention):
  three new assertions — the new file exists, names `github.com/grafana` with its
  6-tool count, and Q16's Gap line points at the new file instead of restating the
  old open gap.

`make ci` passes. No live-cluster dependency — pure doc synthesis from data that
already exists in-repo.

## ADR-0004 caveat

The per-org tool counts are computed directly from `docs/dependency-register.md`'s
committed table (re-verified via a small parsing script during authoring, not
eyeballed), so they're accurate as of this PR. They will drift the same way the
register itself can drift (documented in both files' "Keeping this in sync"
sections) if a future ADR adds/removes/renames a dependency without a matching
update here — no mechanical guard connects the two files, matching the register's
own honestly-stated limitation.

## Rollback path

Revert this commit — new doc file, two doc edits, and additive bats assertions only;
no other surface affected.

## PR

(filled in after PR creation)
