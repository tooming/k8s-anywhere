- [ ] 🟡 **Bump Longhorn `1.7.3` → `1.11.x`** (CHARTER **Core Values** §"Everything as
  code" + general hardening; RFC #528 — architect decision 2026-07-18). Longhorn's
  `1.7.x` line reached end-of-life 2025-09-04 (one year after its first stable
  release, under the pre-1.8 12-month support policy); this lab's pinned
  `targetRevision: 1.7.3` (`gitops/platform/longhorn.yaml`) has received no security
  patches for roughly a year — a version-currency gap, not a single named CVE.
  Lower urgency than a typical bump since Longhorn is **on-demand** (ADR-0013,
  never auto-synced) — zero exposure unless the maintainer runs `make longhorn-up`.
  **No prerequisites — executor may pick up immediately**, but per RFC #528's
  acceptance criteria the executor MUST independently re-verify the exact target
  version at pickup time (Longhorn ships on a fast 4-month cadence; "latest stable
  one line behind newest" may have moved) rather than assume this RFC's `1.11.x`
  pin is still current. Bump `gitops/platform/longhorn.yaml`'s `targetRevision`;
  diff the chart's `values.yaml` between old and new pins for every key this repo
  sets (mirror the Velero bump's verification method); confirm the V2 Data Engine
  stays opt-in, not default, at the new pin. Update
  `docs/decisions/adr-0013-longhorn-block-storage.md` with the new pin + a
  `## Re-evaluation log` entry (trigger: 1.7.x EOL, not a CVE). Update or add a
  chart-pin assertion in `tests/longhorn.bats`. Fix `docs/dependency-tree.md`'s
  stale "v1.7.2" Longhorn reference to the new pin while touching that doc. `make
  ci` must pass. PR body must document the EOL trigger, the version chosen and why,
  the values.yaml diff performed, and the ADR-0004 caveat that this remote
  clusterless session cannot verify Longhorn's CSI driver/UI start cleanly on a
  live cluster post-bump — call out the rollback path (revert `targetRevision`;
  on-demand and not currently synced, so no live-cluster risk unless the
  maintainer already has it running with real volumes — note that caveat
  explicitly). `docs/done/` entry required. Closes #528.
  (auto/longhorn-bump-1-11)
