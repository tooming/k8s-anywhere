- [ ] 🟡 **Bump Cilium chart `1.17.18` → `1.18.12`** (CHARTER **Core Values**
  §"Everything as code" + general hardening; RFC #917 — architect decision
  2026-07-30, ADR-0014 audit #916 resolved as **Convert**. **No prerequisites —
  executor may pick up immediately.**) Cilium's `SECURITY.md` support table now
  marks every version `< 1.18.0` as unsupported (verified directly, not
  training knowledge — ADR-0004); this lab's `1.17.18` pin
  (`gitops/platform/cilium.yaml`) is on that unsupported line. This is the
  exact flip condition ADR-0014's 2026-07-28 Re-evaluation log entry (audit
  #772) recorded in advance. Cilium's own upgrade path is sequential
  minor-by-minor, so this item is deliberately one step (`1.17.18` →
  `1.18.12`, the latest `1.18.x` patch per `git ls-remote --tags
  https://github.com/cilium/cilium.git`), not the full jump to the current
  `1.20.0` — a future item covers the next step once this one has landed.

  Bump `gitops/platform/cilium.yaml`'s `targetRevision: 1.17.18` →
  `1.18.12`. Re-verify at pickup time (not just this RFC's cached read) that
  the `1.18.12` chart's `values.yaml` still contains every key this
  Application's `valuesObject` sets (`kubeProxyReplacement`,
  `prometheus.enabled`/`port`, `hubble.enabled`, `operator.replicas`/
  `resources`, `resources`) — same due-diligence pattern as the
  Grafana/Pyroscope/ArgoCD chart bumps. Add a new dated entry to ADR-0014's
  `## Re-evaluation log` (after the 2026-07-30 audit #916 entry) recording
  this bump landing, with a new flip condition for the next step (e.g.
  "revisit when `1.18.x` itself reaches end-of-support, or a CVE lands against
  `1.18.12` specifically"). Extend or add a `tests/*.bats` chart-pin assertion
  for Cilium (check for an existing one first) asserting `1.18.12` is present
  in `cilium.yaml` — a recurrence guard mirroring this repo's other
  per-component exact-version pin assertions. Update
  `docs/dependency-tree.md` only if it cites the pinned Cilium version
  explicitly (verify first). PR body must document: the EOL trigger, why
  `1.18.12` (smallest safe delta / sequential-upgrade step), and the
  ADR-0004 caveat that this remote clusterless session cannot verify Cilium
  continues routing pod traffic cleanly post-bump on a live cluster — call
  out the rollback path (revert `targetRevision`; ArgoCD self-heals; Cilium
  is a DaemonSet, so a revert re-rolls the same way the bump did, per the
  existing rollback note already in `cilium.yaml`'s header comment). `make ci`
  must pass. `docs/done/` entry required. Closes #917.
  (auto/cilium-1-18-12-bump)
