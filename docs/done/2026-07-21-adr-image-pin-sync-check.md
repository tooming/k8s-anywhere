# ADR image-pin sync check — recurrence guard for a bug class this run's own PR would otherwise have re-introduced

(CLAUDE.md §"Every bugfix must prevent recurrence" — janitor fallback role, invoked
via `executor.prompt.md` STEP 6b after the executor's own "Now / next" lane came up
fully gated on maintainer-confirmation prerequisites (issues #631/#632/#633, none
confirmed this run), the planner/architect fallbacks found no new ROADMAP gap or
un-RFC'd 🟡 item, and the triager fallback labeled the three standing issues
(`domain:*`/`readiness:green`/`priority:p1`) — the last real deliverable available
before this cleanup.)

## The gap

`scripts/adr-chart-version-sync-check.sh` (PR #622) guards one specific class of ADR
drift: a self-tracking `### Chart + version` note going stale after a Helm chart
`targetRevision` bump lands without the ADR prose being updated to match (the PR #616
recurrence). But that check only recognizes the `**Chart:** ... pin lives in
<file>'s targetRevision` phrasing — it has no coverage for an ADR that pins a **plain
container image tag** inline instead, the shape ADR-0009 (RabbitMQ) uses because
RabbitMQ is deployed via a plain `StatefulSet`, not a Helm chart (ADR-0009 §"Plain
manifests over a Helm chart / operator").

This run's own upgrade-drafter cycle (`auto/rabbitmq-4.3.2-to-4.3.3`, upstream
`rabbitmq/rabbitmq-server` v4.3.3, 2026-07-20) bumped `gitops/data/rabbitmq/
statefulset.yaml`'s image tag and, by hand, kept ADR-0009's inline "A pinned official
`rabbitmq:4.3.2-management` image" mention in sync — but nothing would have caught it
if a future run forgot, the exact same failure mode `adr-chart-version-sync-check.sh`
already prevents for the chart-based case. A guard that covers one self-tracking
phrasing but not the other is a guard with a known hole in it.

## The fix

New `scripts/adr-image-pin-sync-check.sh`: discovers every ADR using the "A pinned
official `<image>:<tag>` image" phrasing (no hardcoded list — self-maintaining, same
philosophy as its chart-version sibling), locates the live manifest via that ADR's
own `## Files` table (the first backtick-quoted `gitops/...` path whose filename is a
`statefulset`/`deployment`/`daemonset` manifest — where an `image:` line actually
lives, as opposed to the ArgoCD `Application` root file), and asserts the two tags
match. Wired into `make ci` (`adr-image-pin-sync-check` target) and
`.github/workflows/ci.yml` (kept in parity, `scripts/ci-parity-check.sh` verifies).

Extended the existing `scripts/adr-chart-version-sync-hook.sh` `PostToolUse` hook
(rather than adding a second hook script) to also run the new check — its trigger
filter (`docs/decisions/*` or `gitops/*`) already covers exactly the files either
check cares about, so one hook now runs both self-tracking-note checks.

Coverage: `tests/fixtures/adr-image-pin-sync/{in-sync,drift,no-self-tracking}/`
(mirrors `tests/fixtures/adr-chart-version-sync/`'s three-fixture shape exactly);
four new assertions in `tests/drift-detectors.bats` for the check script itself; three
new assertions in `tests/hook-scripts-coverage.bats` for the hook's new behavior
(a matching tag exits 0, a drifted tag exits 2, and the real ADR-0009 — currently in
sync — exits 0).

Behavior-preserving: no existing check's pass/fail set changed; the chart-version
check function itself was not touched, only the hook script gained a second `if`
block. Verified directly (ADR-0004): `bash scripts/adr-image-pin-sync-check.sh`
passes against the real repo (`adr-0009-rabbitmq-message-broker.md: pinned image
(rabbitmq:4.3.3-management) matches gitops/data/rabbitmq/statefulset.yaml's live
tag`), `scripts/ci-parity-check.sh` passes, and the full `tests/drift-detectors.bats`
+ `tests/hook-scripts-coverage.bats` suites pass for every assertion this change
touches.

The same local sandbox tooling quirk a prior run today already documented
(`docs/done/2026-07-21-adr-chart-version-sync-hook-coverage.md`) applies here too:
this session's `/usr/bin/yq` is `kislyuk/python-yq` (a different, jq-based
implementation) rather than the `mikefarah/yq` Go binary the repo's `yqs()` test
helper expects — several *pre-existing*, unrelated bats assertions
(`argo-rollouts.bats`, `kargo.bats`, `helm-chart-pin-check`, `argocd-crd-ssa-check`,
`rollouts-plugin-list-check`, and their `*-sync-hook` counterparts) fail under it,
reproducing identically on unmodified `main` (confirmed via `git stash`) — a local
environment quirk, not a repo bug, and out of this bounded cleanup's scope. Neither
this check nor the hook it extends calls `yq` at all (both parse ADR/manifest text
with plain `grep`/`awk`/`sed`), so this change is unaffected by that quirk either
way. `make ci` passes (modulo the pre-existing, unrelated yq-mismatch failures).

## PR

(filled in after PR creation)
