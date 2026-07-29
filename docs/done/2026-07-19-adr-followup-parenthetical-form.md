# Fix stale `(follow-up item)` markers in ADR-0028/ADR-0029 + widen `scripts/adr-followup-check.sh` to catch the parenthetical form

(CHARTER **Core Values** §"Docs & dashboards don't drift"; planner gap-analysis
finding, 2026-07-19 — **no prerequisites, executor may pick up immediately**.)
Verified directly against the actual repo state (not assumed, per ADR-0004): five
table rows across two ADRs still carried a `(follow-up item)` annotation for work
that has already shipped and is already tested:

- `docs/decisions/adr-0028-cert-manager-tls-lifecycle.md` lines 192-194: the
  HTTPS `:443` listener (`gitops/network/gateway.yaml:32-34`), the wildcard
  `Certificate` (`gitops/network/certificates/wildcard-certificate.yaml`), and
  the `:8443` frontdoor port mapping (`scripts/bluegreen-frontdoor.sh`,
  `scripts/frontdoor-ensure.sh`) all exist and are covered by
  `tests/cert-manager.bats` (listener + certificate) and
  `tests/frontdoor-https.bats` (port mapping).
- `docs/decisions/adr-0029-keda-event-driven-autoscaling.md` lines 184-185: the
  cert-manager webhook TLS wiring (`gitops/platform/keda.yaml`'s
  `certificates.certManager.enabled: true` block referencing the `k8s-lab-ca`
  issuer) and the `ScaledObject`/`TriggerAuthentication` demo
  (`gitops/data/demo/keda-scaling/{scaledobject,triggerauthentication}.yaml`)
  both exist and are covered by `tests/keda.bats` / `tests/keda-scaledobject.bats`.

`scripts/adr-followup-check.sh` (the mechanical guard for exactly this drift
class — its own header comment cites the ADR-0006/CHARTER precedent from
`docs/done/2026-07-19-adr-followup-check-widen-scope.md`) only grepped for the
capitalized literal `Follow-up:` and did not catch this parenthetical
`(follow-up item)` form, so it stayed green through both of these going stale —
the same undetected-drift failure mode the script exists to prevent, recurring
in a second syntactic shape.

## What changed

1. Edited the five stale table cells in ADR-0028/ADR-0029 to drop the
   `(follow-up item)` annotation and cite the concrete shipped file + covering
   bats file instead. Also corrected a stale path in ADR-0028's table
   (`gitops/network/wildcard-certificate.yaml` → the real
   `gitops/network/certificates/wildcard-certificate.yaml`).
2. Widened `scripts/adr-followup-check.sh`'s `grep` pattern from the single
   literal `'Follow-up:'` to the alternation `'Follow-up:|\(follow-up item\)'`
   (`grep -lE`), updated the header comment and both user-facing messages to
   name both shapes. No other script structure change — same exit-2/CI/hook
   wiring.
3. Added a new drift fixture,
   `tests/fixtures/adr-followup-check/drift-adr-parenthetical/`, carrying a
   `(follow-up item)` table-cell annotation, and a new
   `tests/drift-detectors.bats` case asserting the check fails on it. Confirmed
   manually that the existing `in-sync`/`drift-adr`/`drift-charter` fixtures and
   the "passes on the real repo" case are unaffected by the widened pattern.

Behavior-preserving for every previously-passing case; this only adds a second
pattern alternative to the same grep. `make ci` passes.

## PR

[#601](https://github.com/tooming/k8s-anywhere/pull/601)
