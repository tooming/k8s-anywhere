# Oldest dependency-register rows re-swept — Garage, RabbitMQ, Tempo confirmed clean; Forgejo unreachable

Continuing the "rank by Last-reviewed date, check the oldest" lens from the
previous cycle's Pyroscope check. Re-verified the next three oldest
untouched rows.

## What was checked

Directly against live sources (ADR-0004):

- **Garage** (last checked 2026-08-19): `github.com/deuxfleurs-org/garage`'s
  tags list confirms `v2.3.0` (Apr 16, 2026) is still the newest tag; zero
  published security advisories, unchanged.
- **RabbitMQ** (last checked 2026-08-19): Docker Hub's tags API confirms
  neither `4.3.6-management` nor `4.4.0-management` exist — `4.3.5-management`
  still the newest patch on the `4.3.x` line.
- **Tempo** (last checked 2026-08-13): Docker Hub's tags API confirms neither
  `2.10.9` nor `2.11.0` exist — `2.10.8` still the newest tag.

**Forgejo** (last checked 2026-08-17) was attempted but not checkable this
cycle: `codeberg.org` (its actual host) is egress-blocked from this sandbox,
consistent with this run's already-documented limitation for that domain —
not silently skipped, explicitly noted as unreachable rather than assumed
current.

## Decision: all three kept, no action needed

No currency or security gap found in any of the three. Recorded as a genuine
re-confirmation, not filler: each check re-verifies a real claim from 2-3
weeks ago against a live source, closing the possibility that it went stale
unnoticed.

## What changed

- `docs/decisions/adr-0002-garage-not-minio.md`,
  `adr-0009-rabbitmq-message-broker.md`,
  `adr-0006-grafana-native-git-sync.md` (Tempo's real bump history lives
  here, not ADR-0034): one new Re-evaluation log entry each.
- `docs/dependency-register.md`: Garage, RabbitMQ, Tempo rows updated; the
  Grafana row's date also bumped (no new Grafana-specific finding — its ADR
  column cites ADR-0006 directly, and that ADR's log gained the Tempo entry
  above, so the sync check correctly required the date to move too).

No `gitops/` change. `make ci` passes green.

## PR

(filled in after PR creation)
