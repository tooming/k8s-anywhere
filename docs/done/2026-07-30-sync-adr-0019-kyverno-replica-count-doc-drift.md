# Fix stale Kyverno replica-count/chart-version claims in ADR-0019 + docs/dependency-tree.md

PR #928 (today) bumped `gitops/platform/kyverno.yaml`'s `admissionController.replicas`
from `1` to `2` to close a fail-closed webhook self-lockout risk (with 1 replica, that
pod restarting under load leaves the `resourceValidatingWebhookConfiguration` webhook
with zero endpoints, blocking every delete/create cluster-wide until it recovers — hit
live 2026-07-29). The manifest itself carries a detailed inline comment explaining the
exception, but two docs describing the same "footprint controls" config were not
updated to match:

1. **`docs/decisions/adr-0019-kyverno-admission-engine.md`**'s "Footprint controls"
   section still showed `admissionController: { replicas: 1, ... }` in its code
   block and a stale "~600 MiB combined limits" total (computed for 1 replica, not
   2) — the ADR's own governing text no longer matched its governed component.
2. **`docs/dependency-tree.md`**'s Kyverno bullet said "Single-replica per
   controller (ADR-0005 lab trade-off)" with no carve-out noted, and separately
   cited chart `v3.3.9` — stale since a re-evaluation log entry (2026-07-27, audit
   #760) already recorded the chart being bumped to `3.8.2` (appVersion `v1.18.2`)
   back on 2026-07-19. Both were quietly out of sync with the live pin.

## Fix

- Updated ADR-0019's "Footprint controls" code block to `replicas: 2` for
  `admissionController`, corrected the total to ~832 MiB (512 MiB for the two
  admission-controller replicas + 320 MiB for the other three single-replica
  controllers), and added a new dated `## Re-evaluation log` entry (2026-07-29)
  recording the trigger/decision/flip-condition, mirroring the manifest's own
  inline comment so the ADR is the durable record of the same reasoning.
- Updated `docs/dependency-tree.md`'s Kyverno bullet to note the
  `admissionController` 2-replica carve-out and to cite the correct chart version
  `v3.8.2`.

No topology/decision change — both are pure doc reconciliation to match state that
already shipped in PR #928 and the 2026-07-27 chart bump. `make ci` passes (2345
assertions, 0 failures — `markdown-links-check` confirmed the new ADR anchor link
resolves).

## PR

(filled in after PR creation)
