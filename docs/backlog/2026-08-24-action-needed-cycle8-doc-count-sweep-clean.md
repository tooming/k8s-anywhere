# [Action needed] Now/next still gated; doc-count sweep clean (cycle 8)

Autonomous scheduled run — the executor's honest STEP 6b fallback record for
this cycle, `executor.prompt.md` STEP 6b, eighth cycle of this run.

## Now / next status

Unchanged from every earlier cycle this run: all three unchecked ROADMAP
items remain gated (rename/decommission GitLab-migration items need live
verification; capstone `Deployment` removal gated on issue #633). Re-checked
issue #633 directly this cycle: still open, no new comment since
2026-08-17T18:50:01Z — the same "no Freight ever produced, host-capacity
ceiling repeatedly blocking Harbor+Kargo running together" blocker every
prior comment already established, unchanged.

## What this cycle tried (a fresh angle from cycles 1-2/4-5/7's
## dependency-register.md/dora-audit-readiness.md focus, and cycle 6's
## CI-tooling focus)

Cycles 1, 4, 5, and 7 this run all found and fixed real staleness in the
`docs/dependency-register.md` family (a genuine, recurring vein — 3 rows,
then a 4th, then a mechanical-guard extension, then a Scope-note arithmetic
bug). This cycle deliberately checked a *different* family of hand-maintained
count-based docs, on the theory that the same "prose citing a number that
drifts when reality changes" failure mode might recur elsewhere:

- **`docs/00-architecture.md`**'s Grafana row claims "32 lab dashboards...
  39 dashboard files total, minus the 7 tied to on-demand/heavy components."
  Verified directly: `ls grafana/dashboards/*.json | wc -l` → **39**, matching
  exactly. The named 7 on-demand-tied dashboards (Harbor, Inkless, Istio,
  Kargo, Longhorn, TiDB ×2) also check out: 39 − 7 = 32. **No drift.**
- **`docs/dependency-exit-runbooks.md`**'s three concentration-group tool
  counts (`github.com/grafana` — 6 tools; `github.com/argoproj` — 2; `
  github.com/pingcap` — 2) — all three groups are unaffected by ADR-0036
  (External Secrets Operator, this run's own cycle-7 finding), since
  `external-secrets` is its own distinct org, not a member of any of these
  three groups. **No drift.**
- **`docs/DR.md`** — no numeric stateful-namespace/Schedule/backup count
  claims found in the file at all (checked via grep for the pattern this
  cycle was hunting); nothing to verify.
- **CHARTER.md's "~33 ArgoCD Applications" figure** (re-counted 2026-07-29,
  issue #846) — attempted a mechanical re-derivation and deliberately
  **abandoned it rather than force a low-confidence fix**: the figure's own
  methodology hand-groups multiple `Application` YAML files into one
  conceptual component (e.g. "envoy-gateway(+system-extras/-networkpolicy)"
  counted as one), which a raw `grep -c 'kind: Application'` can't safely
  reproduce without redoing that same subjective grouping work — attempting
  it risked introducing a *new*, harder-to-spot error while claiming to fix
  an old one. Flagging honestly rather than asserting a number this session
  isn't confident in (ADR-0004) — a future cycle with more budget for the
  full manual re-derivation (matching issue #846's own methodology) could
  pick this up properly; noted here as a real, scoped-out candidate rather
  than silently dropped.

**`make ci`:** green (unchanged from the prior cycle; nothing in this repo
needed a change this cycle).

Going straight back to STEP 1 per STEP 8 — this is not a stopping point.
