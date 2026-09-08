# [Action needed] Cycle 17 — this run's doc-drift/currency-check lens is exhausted for now

This autonomous executor run has landed 16 merged PRs so far this session
(cycles 1–16, PRs #1513–#1529), largely mining one rich vein: leftover
rationale/config from the 2026-09-06/2026-09-07 aggressive simplification
that removed most of this lab's prior component set. That vein is now
substantially exhausted after a genuinely broad sweep. This cycle's own
search (a fresh pass, not a repeat) came up empty — recorded here per
`executor.prompt.md` STEP 6b's last resort, not as a reason to stop the
run (STEP 8).

## What this cycle checked (all came up clean)

- **`docs/incident-log.md`'s remaining "Follow-up" column entries** (beyond
  the 2026-09-06 k3s-datastore one already fixed in #1526): the 2026-08-07
  Kargo/Harbor DNS gap and the 2026-08-25 NetworkPolicy
  port/namespace-selector footgun are both about namespaces/components that
  no longer exist (Kargo, Harbor) — their own follow-ups are moot, not
  actionable. The 2026-08-11 k3s datastore-compactor entry's "no mechanical
  guard possible" is an honestly-accepted upstream limitation, not a
  flagged-but-undone task.
- **Other stale "checked YYYY-MM-DD, not yet met" ADR flip conditions**
  beyond the `lab-demo` one already re-verified and flipped (#1527, #1529):
  none remain — `grep -rn "Flip condition:\*\* .*checked 20" docs/decisions/*.md`
  now returns zero hits.
- **Upstream currency for the lab's 4 core always-on components** (k3s,
  ArgoCD, Traefik, cert-manager): k3s `v1.36.4+k3s1` is already the latest
  stable (only `v1.37.0-rc*` pre-releases exist beyond it, per
  `git ls-remote --tags`); cert-manager `1.21.1` is already the latest
  stable tag; ArgoCD chart was already bumped this run (`10.5.0`→`10.8.2`,
  #1524); Traefik tracks k3s's own bundled version (ADR-0030), unchanged.
  Nothing left to bump.
- **Cross-checking other docs claims against the manifests they describe**
  (the lens that found the `lab-demo`/HotROD gap, #1528/#1529): re-swept
  `README.md`, `CHARTER.md`, `docs/00-architecture.md`,
  `docs/dependency-tree.md`, `docs/dora-audit-readiness.md`,
  `docs/platform-products.md` for any remaining current-state claim not
  matching the real manifest — found none.
- **`docs/roadmap/investigations/`**: only one file remains
  (`2026-08-17-gitlab-forgejo-rename.md`), and it's linked as the permanent
  historical record from an already-`[x]`-checked, closed-as-moot ROADMAP
  item (same status as any `docs/done/` writeup) — not orphaned, not a
  cleanup candidate; deleting it would break that historical link.
- **Duplication in `scripts/lib/`**: 9 small, already-focused files (281
  lines total) — no near-identical logic left to extract; prior JANITOR
  cycles already did this consolidation (`ok()`/`bad()` → `colors.sh`, the
  `yqs()` dedup, etc., per ROADMAP's own `[x]` history).
- **`Makefile` target ↔ docs cross-reference**: every `make <target>` cited
  in README.md/docs/DR.md/docs/dependency-tree.md resolves to a real
  Makefile target (spot-checked 16 names directly) — no drift.
- **CHARTER.md's O2 objective** (default-deny + PSS-restricted by
  2026-09-30): unaffected by this run's `lab-demo` PSS flip (#1529) in a
  way that needs a CHARTER edit — the objective's bar and its "measured
  by" line are both namespace-count-independent.

## What would open new work

- A new upstream release against the lab's 4-component core (k3s, ArgoCD,
  Traefik, cert-manager) — all four are current as of this cycle.
- A new GitHub issue, RFC, or CHARTER edit from the maintainer.
- Issue [#1517](https://github.com/tooming/k8s-anywhere/issues/1517)
  (coredns-host-alias vestigial-step removal) resolving — it's gated on
  live-cluster verification this remote session can't perform.
- A future cycle finding a genuinely different angle this sweep's scope
  didn't cover (this run has now tried: removed-component leftover
  rationale, incident-log follow-ups, ADR flip-condition staleness,
  dependency currency, and docs-vs-manifest cross-checks).

This is this cycle's honest record, per `executor.prompt.md` STEP 6b's
last resort. The run continues (STEP 8) — going back to STEP 1
immediately.
