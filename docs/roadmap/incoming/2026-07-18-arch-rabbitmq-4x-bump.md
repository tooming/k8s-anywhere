- [ ] 🟡 **Bump RabbitMQ `3.13` → `4.3.x`** (CHARTER **Core Values** §"Everything as
  code" + general hardening; RFC #522 — architect decision 2026-07-18). RabbitMQ's
  community-support policy now covers only the current + previous minor series
  (`4.3.x` / `4.2.x`); this lab's pinned `rabbitmq:3.13-management` (four minor
  series back) no longer receives free security patches — a version-currency gap,
  not a single named CVE. **No prerequisites — executor may pick up immediately**,
  but per RFC #522's acceptance criteria the executor MUST independently re-verify
  the direct 3.13 → 4.3 upgrade path (Mnesia → Khepri automatic migration) against
  RabbitMQ's own current upgrade docs at pickup time before landing — do not assume
  the RFC's summary is still accurate. Bump
  `gitops/data/rabbitmq/statefulset.yaml`'s image tag to `rabbitmq:4.3.2-management`
  (or the latest `4.3.x` patch at pickup time). Update `docs/decisions/adr-0009-rabbitmq-message-broker.md`
  with the new pin + a `## Re-evaluation log` entry (trigger: support-window lapse,
  not a CVE — mirror the ADR-0017/ADR-0020 log pattern). Add new bats coverage
  pinning the RabbitMQ image tag (none exists today — checked `tests/data-layer.bats`).
  `make ci` must pass. PR body must document the executor's own upgrade-path
  re-verification and the ADR-0004 caveat that this remote clusterless session
  cannot confirm the Mnesia→Khepri migration completes cleanly against this lab's
  live persisted queue data on a real cluster — call out the rollback path
  prominently (revert the image tag; note a stateful-format downgrade may not be
  clean, so recovery may require `make dr-restore`/reseed rather than a clean
  revert, per ADR-0005's already-accepted single-node recreate-over-HA risk
  posture). `docs/done/` entry required. Closes #522.
  (auto/rabbitmq-bump-4x)
