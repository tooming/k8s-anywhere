# Valkey ADR image-pin drift fix + mechanical guard extension

(CHARTER **Core Values** §"Everything as code"; JANITOR-fallback bounded cleanup
2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role, this run's 14th
cycle, after the Now/next lane was re-confirmed fully gated. **No prerequisites —
executor may pick up immediately.**)

## What was wrong

ADR-0018 (Valkey)'s "Plain manifests over a Helm chart" section had a stale inline
image-tag mention: `a pinned `valkey/valkey:8.0-alpine` image` — the pre-CVE-bump
tag. The live pin (`gitops/data/valkey/statefulset.yaml` and
`gitops/data/demo/valkey-load.yaml`) has been `valkey/valkey:8.0.10-alpine` since
2026-07-22 (PR/RFC #655, audit #654 — a real security bump fixing CVE-2026-56684 and
CVE-2026-63639), and ADR-0018's own Re-evaluation log *correctly* documents that
bump in detail. Only this one prose sentence — a separate, earlier-in-the-file
mention, not the re-evaluation log itself — was never updated, so the ADR
contradicted its own later section.

Found this cycle following up on cycle 12's Kargo finding: after fixing Kargo's
guard gap in `scripts/adr-chart-version-sync-check.sh`, checked the ADR
image-pin guard's real-repo coverage (`scripts/adr-image-pin-sync-check.sh`) and
found it only exercises ADR-0009 (RabbitMQ) — one self-tracking ADR is thin
coverage for a guard whose whole purpose is catching this exact class of drift, so
audited every other plain-manifest component's ADR for the same "pinned `<image>`"
prose pattern and found Valkey's mismatch directly (`git log` on the manifest
confirms the bump commit `e0b7007`, "fix(security): bump Valkey image tag
8.0-alpine -> 8.0.10-alpine (CVE-2026-56684, CVE-2026-63639) (#658)").

## Fix

Updated ADR-0018's "Plain manifests over a Helm chart" sentence to cite the real
current pin (`8.0.10-alpine`) and cross-reference the Re-evaluation log for the bump
history, matching the phrasing convention `docs/decisions/adr-0009-rabbitmq-message-broker.md`
already uses.

## Mechanical guard (this bugfix's second deliverable)

`scripts/adr-image-pin-sync-check.sh` only matches the literal phrase `pinned
official `<image>:<tag>`` — ADR-0018's original sentence said `a pinned
`valkey/valkey:8.0-alpine`` (no "official"), so it never opted into the guard the
same way ADR-0023 never opted into the chart-version guard until cycle 12. Added
"official" to the sentence — accurate, not fabricated: `valkey/valkey` is the
Valkey project's real official Docker Hub image, same category as
`rabbitmq:4.3.4-management` (also an official image). Re-ran
`adr-image-pin-sync-check.sh` against the real repo and confirmed it now picks up
ADR-0018 automatically — the script is explicitly self-maintaining, no
script-logic changes needed. Updated the script's own header comment and extended
`tests/drift-adr-sync-checks.bats`'s real-repo assertion to also require
`adr-0018` in the passing output, so a regression fails the guard's own tests.

Same pattern as PR #1142 (Kargo/ADR-0023): "make the bug impossible by
construction" (CLAUDE.md's bugfix hierarchy, option (a)) — the next Valkey image
bump that forgets to update ADR-0018's prose will now fail
`make adr-image-pin-sync-check` (wired into `make ci`'s `drift` gates).

## ADR-0004 caveat

The corrected tag (`8.0.10-alpine`) was read directly from the live manifest and
matches ADR-0018's own already-correct Re-evaluation log entry — not re-derived or
guessed.

## Rollback path

Revert this commit. No other file depends on ADR-0018's phrasing format; the
guard-script/bats changes are additive and independently revertible.

## PR

(filled in after PR creation)
