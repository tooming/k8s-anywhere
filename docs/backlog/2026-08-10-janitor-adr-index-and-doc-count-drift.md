# Janitor note — 2026-08-10 (ADR index gap + stale counts/status across 5 docs)

**Reached via:** `executor.prompt.md` STEP 6b, JANITOR fallback, fifteenth cycle this
run. Sixth consecutive subagent-delegated deep gap-analysis sweep (following cycles
10-14's real ADR-0019/ADR-0016/ADR-0021/dependency-register/README findings), this
time targeting the remaining unswept ADRs, governance ADRs, `docs/00-architecture.md`,
the ADR index itself, and `docs/dora-audit-readiness.md`'s previously-flagged-minor
gaps.

**What was found — six independently-verified drift bugs, all record-correction
(content already exists and is already tested elsewhere; only the prose describing it
was stale), so none gets a new mechanical guard per CLAUDE.md's bugfix triage — same
class as PR #1091/#1092/#1093/#1094:**

1. `docs/decisions/README.md` (the ADR index) listed ADRs only through ADR-0032 —
   ADR-0033 (GitLab) and ADR-0034 (LGTMP observability internals), both real, adopted,
   retroactive ADRs from RFC #1073, were undiscoverable through the canonical index.
   Fixed: added both entries.
2. `docs/decisions/adr-0013-longhorn-block-storage.md`'s status line still said
   "Manifests pending (next ROADMAP item)" — `gitops/platform/longhorn.yaml` has
   existed and been actively version-bumped (per the ADR's own Re-evaluation log) for
   months. Fixed: status line now says manifests are live.
3. `docs/dora-audit-readiness.md` Q14 cited "22 tools across 20 ADRs" for the
   dependency register — direct count of the actual table is 32 tools across 24 ADRs
   (ADR-0031/0032/0033/0034 each added rows since this line was last touched). Fixed.
4. `docs/dependency-register.md`'s own "Scope note" said "32 ADRs... (ADR-0001–
   ADR-0032)" while the same file's body 40 lines below already discusses ADR-0033 and
   ADR-0034 as real, existing ADRs with their own table rows — a self-contradiction
   within one file. Fixed: scope note now says 34 ADRs.
5. `docs/platform-products.md` described TiDB, Istio+Kiali, Longhorn, and the artifact
   registry (still naming "Artifactory/Nexus", superseded by Harbor per ADR-0024) as
   `📋 planned (heavy)` — all four are real, built, on-demand components with pinned
   chart versions, dedicated ADRs (0012, 0013, 0024, 0031/0032), and working `make
   <name>-up` targets. Fixed across the Tier-5 mermaid diagram, its priority table row,
   the three product-catalog rows, the intro paragraph, and the team-ownership table's
   parenthetical — all now read "on-demand, built" instead of "planned", and "Harbor"
   instead of "Artifactory/Nexus".
6. `docs/decisions/adr-0029-keda-event-driven-autoscaling.md`'s "Out of scope, explicit
   follow-ups" section described cert-manager TLS wiring and a real `ScaledObject` demo
   as future work — the same document's own "Files this work will touch" table already
   tags both rows "(shipped; see tests/keda.bats)" / "(shipped; see
   tests/keda-scaledobject.bats)", and the manifests
   (`gitops/platform/keda.yaml`'s `certificates.certManager` block at sync-wave 6,
   `gitops/data/demo/keda-scaling/{scaledobject,triggerauthentication}.yaml`) are real
   and live. Fixed: relabeled the section header to reflect both items shipped, per the
   Files table.

**Every claim independently re-verified before writing** (ADR-0004): read both sides
of each contradiction directly — the stale line and the file/table it disagrees with —
rather than trusting the subagent's report on faith. Confirmed `tests/keda.bats` and
`tests/keda-scaledobject.bats` both exist, `gitops/platform/keda.yaml` has
`sync-wave: "6"` and a `certManager` block, and `gitops/data/demo/keda-scaling/` has
both manifests, before touching the KEDA ADR.

**Sweep scope this cycle (for the record):** all governance ADRs (0003/0005/0025/0026)
had no concrete checkable claims (principle-level, not factual). `docs/00-architecture.md`
was cross-checked (including its dashboard-count arithmetic) and found accurate — not
a finding. `docs/dependency-tree.md` was checked and is the document that *correctly*
already describes Harbor/Istio/Longhorn/TiDB as on-demand and built, exposing
`platform-products.md` as the stale outlier. `docs/dora-audit-readiness.md` Q13/Q15/
Q16/Q17 were re-read fresh and independently re-confirmed as genuine, self-acknowledged
process gaps (no factual mismatch against another file) — not acted on, consistent with
prior cycles' judgment. ADR-0008/0012/0020/0022/0023/0024/0027/0028/0029/0030/0031/0032
version-pin and chart-field claims were all spot-checked against the live
`gitops/*.yaml` and found to match exactly — no drift.
