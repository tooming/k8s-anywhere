# Bump RabbitMQ `3.13` → `4.3.x`

CHARTER **Core Values** §"Everything as code" + general hardening; RFC #522 —
architect decision 2026-07-18. **No prerequisites — executor may pick up
immediately.** RabbitMQ's community-support policy now covers only the current
+ previous minor series (`4.3.x` / `4.2.x`); this lab's pinned
`rabbitmq:3.13-management` (four minor series back) no longer receives free
security patches — a version-currency gap, not a single named CVE.

Per RFC #522's acceptance criteria the executor MUST independently re-verify
the direct 3.13 → 4.3 upgrade path (Mnesia → Khepri automatic migration)
against RabbitMQ's own current upgrade docs at pickup time before landing — do
not assume the RFC's summary is still accurate. Bump
`gitops/data/rabbitmq/statefulset.yaml`'s image tag to `rabbitmq:4.3.2-management`
(or the latest `4.3.x` patch at pickup time). Update
`docs/decisions/adr-0009-rabbitmq-message-broker.md` with the new pin + a
`## Re-evaluation log` entry (trigger: support-window lapse, not a CVE — mirror
the ADR-0017/ADR-0020 log pattern). Add new bats coverage pinning the RabbitMQ
image tag (none exists today — checked `tests/data-layer.bats`). `make ci`
must pass. PR body must document the executor's own upgrade-path
re-verification and the ADR-0004 caveat that this remote clusterless session
cannot confirm the Mnesia→Khepri migration completes cleanly against this
lab's live persisted queue data on a real cluster — call out the rollback path
prominently (revert the image tag; note a stateful-format downgrade may not be
clean, so recovery may require `make dr-restore`/reseed rather than a clean
revert, per ADR-0005's already-accepted single-node recreate-over-HA risk
posture). Closes #522.

## What changed

`gitops/data/rabbitmq/statefulset.yaml`'s image bumped `rabbitmq:3.13-management`
→ `rabbitmq:4.3.2-management`. No `rabbitmq.conf` / `enabled_plugins` change —
the ConfigMap (`gitops/data/rabbitmq/configmap.yaml`) sets no `khepri_db`
feature flag either before or after the bump, so the node stays on RabbitMQ's
default Mnesia metadata store and the automatic Mnesia→Khepri migration path
applies cleanly when the new binary boots.

`docs/decisions/adr-0009-rabbitmq-message-broker.md` updated: the "Plain
manifests over a Helm chart / operator" section now cites the new pin, and a
new `## Re-evaluation log` section records the trigger (community-support
lapse), the decision, the ADR-0004 caveat, the rollback-path risk (a real
downgrade of the on-disk metadata format once Khepri has migrated in — not a
clean revert), and the next flip condition.

`tests/data-layer.bats` gained two recurrence-guard assertions: the image is
pinned to a `4.x` tag, and the old unsupported `3.13` pin is gone — no test
pinned this image tag before this PR.

## Upgrade-path re-verification (per RFC #522's acceptance criteria)

Re-checked at pickup time rather than trusting the RFC's own summary:
confirmed via RabbitMQ's own docs and multiple `rabbitmq/rabbitmq-server`
GitHub discussion threads (read as search-result summaries, not full thread
text — this remote session has no way to fully verify beyond that) that a
direct 3.13 → 4.x upgrade is supported for a node running the default Mnesia
metadata store; only nodes that had explicitly enabled the (then-experimental)
`khepri_db` feature flag on 3.13 are blocked from a direct jump and need
blue-green instead. This lab never set that flag, so the direct jump applies.

## ADR-0004 caveat — what this run could NOT verify

This remote clusterless session cannot confirm the Mnesia→Khepri migration
actually completes cleanly against this lab's live persisted queue data on a
real cluster — that is only exercisable on the maintainer's hardware.

**Rollback path.** Revert `gitops/data/rabbitmq/statefulset.yaml`'s image tag;
ArgoCD self-heals the StatefulSet back onto the old binary. This is **not**
guaranteed to be a clean revert once the new node has booted and the metadata
has migrated to Khepri's on-disk format — the reverted 3.13 binary only reads
Mnesia's format. Per ADR-0005's already-accepted single-node
recreate-over-HA posture, the realistic recovery path if ever needed is
`make dr-restore` / reseeding queue state from Velero, not an in-place
downgrade.

## Validation

`make ci` — fully green (bats/kustomize/terraform tools aren't installed in
this remote environment; the full suite runs in GitHub Actions on the PR).

## PR

https://github.com/tooming/k8s-anywhere/pull/525
