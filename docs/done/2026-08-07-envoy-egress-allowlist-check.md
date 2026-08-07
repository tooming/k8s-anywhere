# Envoy backend-egress allowlist — close the recurring gap + add a mechanical guard

Janitor sweep (executor.prompt.md STEP 6b fallback chain, 2026-08-07): the
`allow-envoy-proxy-backend-egress.yaml` NetworkPolicy (ADR-0016, RFC #206) hardcodes
a closed list of namespaces the Envoy data-plane proxy may egress to; a namespace
with a live HTTPRoute through the shared gateway (`parentRefs: eg` / `lab-gateway`)
that's missing from this list has its HTTPRoute responses silently dropped by the
`envoy-gateway-system` default-deny floor. This exact gap caused a real incident for
`harbor` (fixed 2026-08-03, PR #968) — and the only test covering this file just
grepped for the 13 already-known namespace names, so it could never catch a *new*
namespace being added elsewhere without also updating this list. Cross-referencing
every `kind: HTTPRoute` manifest in `gitops/**` against the current allowlist found
the identical bug had recurred, undetected, for four more namespaces: `tidb`
(`gitops/tidb-demo/route.yaml`), `longhorn-system` (`gitops/longhorn/route.yaml`),
`istio-system` (`gitops/kiali/route.yaml`), and `kargo` (`gitops/kargo/route.yaml`).

**Fix:** added the four missing namespaces to
`allow-envoy-proxy-backend-egress.yaml`'s allowlist (13 → 17), updated its own and
its sibling files' (`kustomization.yaml`, `allow-envoy-proxy-xds-egress.yaml`) stale
"twelve"/"thirteen" comments to "seventeen", and extended
`tests/networkpolicy-envoy-gateway-system.bats`'s pin assertions.

**Mechanical recurrence guard (CLAUDE.md's bugfix-prevents-recurrence rule):** new
`scripts/envoy-egress-allowlist-check.sh`, mirroring `scripts/lab-ui-check.sh`'s
shape exactly — walks every `gitops/**/*.yaml` HTTPRoute routed through the shared
gateway, extracts each one's own `metadata.namespace` (not its file path, since some
HTTPRoutes are embedded via `extraObjects` inside an unrelated Application's
values.yaml — e.g. Grafana's), and flags any namespace missing from the allowlist.
One-directional by design: an allowlist entry with no *current* HTTPRoute (e.g.
`kyverno`/`velero`/`trivy-system`/`ack-system` today) is not flagged — over-inclusion
isn't the failure mode that bit us, and pruning those without evidence they're
actually unused risks breaking something this check can't see. Wired into
`make ci` + the GitHub Actions `drift` job (kept in parity), a `PostToolUse` hook
(`scripts/envoy-egress-allowlist-sync-hook.sh`, mirroring `lab-ui-sync-hook.sh`), and
bats coverage in two new scope files (`tests/drift-envoy-egress-allowlist-check.bats`,
`tests/hook-scripts-envoy-egress-allowlist.bats` — both frozen monoliths,
`tests/drift-detectors.bats`/`tests/hook-scripts-coverage.bats`, get new scopes in
their own files per the existing convention).

`make ci` passes (2533 bats tests green, including the new check's own coverage).

## PR

https://github.com/tooming/k8s-anywhere/pull/1062
