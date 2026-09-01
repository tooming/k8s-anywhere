# Bump External Secrets Operator chart `2.9.0` → `2.10.0` (real fixes, additive schema)

(CHARTER **Core Values** §"Everything as code" + general hardening; upgrade-drafter fallback, executor.prompt.md STEP 6b — this run's eleventh cycle: the "Now / next" lane remained fully gated and PLANNER found no ungroomed intake or un-RFC'd 🟡 item. Routine currency sweep found [ADR-0036](../decisions/adr-0036-external-secrets-vault-sync.md)'s "no currency gap" note (dated 2026-08-19) had gone stale.)

Verified directly (not assumed, ADR-0004): `external-secrets/external-secrets`'s `helm-chart-2.10.0` tag is real and one release past the pinned `2.9.0` (confirmed via the repo's own tags listing).

**Schema compatibility verified via a real clone.** `git diff helm-chart-2.9.0 helm-chart-2.10.0 -- deploy/charts/external-secrets/values.yaml` is purely additive (48 insertions, 0 deletions) — new optional `tls.{minVersion,ciphers,curvePreferences}` blocks at the global/webhook/certController levels, every one defaulting to empty (no behavior change unless explicitly set). Every key this lab's `valuesObject` sets (`installCRDs`, `podSecurityContext`, `securityContext`, `webhook.*`, `certController.*`, `resources`) is unchanged in shape.

**Real content, not just currency.** `git log v2.9.0..v2.10.0` (39 commits) includes real fixes: `fix(aws): redact credentials in aws auth config logs` (a real credential-leak fix), `fix(gcp): preserve workload identity token expiry`, `fix(vault): only apply deprecated token-cache flags when explicitly set` — plus the TLS security-profile feature itself (`feat: apply TLS security profile to the external-secrets deployment`) and routine dependency bumps (distroless/golang base image digests, various Go module bumps). No CVE cited explicitly, but real security-relevant fixes.

**This Application is ALWAYS-ON** (automated sync) — this pin takes effect on the next ArgoCD reconciliation.

Bumped `gitops/platform/external-secrets.yaml`'s `targetRevision: 2.9.0` → `2.10.0` and its header comment. Updated `tests/external-secrets-chart-pin.bats`'s pin assertions (retitled, negative assertion extended to include the superseded `2.9.0`). Updated ADR-0036's "Chart + version" note and appended a new dated entry to its Re-evaluation log. Updated `docs/dependency-register.md`'s row.

**ADR-0004 caveat.** This remote clusterless session cannot verify the External Secrets Operator pods actually restart cleanly on the new chart version on a live cluster, or that secret sync continues uninterrupted. Since this is always-on/auto-synced, that verification should happen promptly after this merges. Rollback path: revert `targetRevision` back to `2.9.0`.

## PR

https://github.com/tooming/k8s-anywhere/pull/1370
