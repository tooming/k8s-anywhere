# Sync ADR-0019/ADR-0017/namespace.yaml after PR #1217's inkless carve-out removal

(follow-up fix; executor-fallback JANITOR pass 2026-08-18, fifth cycle this run,
reached via `executor.prompt.md` STEP 6b after PLANNER/ARCHITECT/DOC-DRIFT-AUTHOR/
TRIAGER all found nothing new this cycle and UPGRADE-DRAFTER's cap was already
spent. This cycle's fresh angle: re-swept `gitops/kyverno/policies/disallow-
latest-tag.yaml`'s sibling documentation for the `inkless` carve-out PR #1217
removed, looking for any citation PR #1217 itself missed updating.)

**Found:** `docs/decisions/adr-0019-kyverno-admission-engine.md`'s Decision-section
table row and bullet still described the `disallow-latest-tag` policy's `exclude`
list as `[capstone, inkless]` and the `inkless` carve-out as still active — both
now factually wrong after PR #1217 removed `inkless` from the live exclusion list.
`gitops/inkless/namespace.yaml`'s own header comment and `docs/decisions/
adr-0017-pod-security-standards-restricted.md`'s `inkless` PSA-carve-out table row
also still cited the stale `ghcr.io/aiven/inkless:latest` image reference PR #1217
already bumped to `:4.2.1-0.46`. This is exactly the kind of same-run drift CLAUDE.md's
"every bugfix must prevent recurrence" principle applies to at a smaller scale: a
change should keep its own downstream citations in sync in the same PR, and when it
doesn't, the very next cycle should close the gap rather than let it compound.

**Fix:**
- `docs/decisions/adr-0019-kyverno-admission-engine.md`: updated the Decision-section
  table row + bullet to describe both the `argocd` (2026-08-06, already correct) and
  `inkless` (2026-08-18, PR #1217) carve-out removals; exclude list now correctly
  cited as `[capstone]` only. Added a Re-evaluation log entry mirroring the existing
  `argocd` carve-out removal entry's shape.
- `gitops/inkless/namespace.yaml`: replaced the stale `:latest` tag citation with a
  pointer to the statefulset's own current pin, and expanded the PSA flip condition
  to state both halves (Dockerfile evidence met; live-cluster verification still
  outstanding — ADR-0004 ceiling for this remote clusterless session), matching
  ADR-0017's own fuller wording.
- `docs/decisions/adr-0017-pod-security-standards-restricted.md`: updated the
  `inkless` PSA-carve-out table row's image citation to the current pin, noting the
  prior `:latest` value for continuity.

No behavior change — every edit is a documentation citation correcting itself to
match the already-merged, already-verified reality from PR #1217. `make ci` passes
(markdown-links-check, adr-guard-hook both clean; no test asserted the stale text,
so nothing needed updating there).

## PR

https://github.com/tooming/k8s-anywhere/pull/1219
