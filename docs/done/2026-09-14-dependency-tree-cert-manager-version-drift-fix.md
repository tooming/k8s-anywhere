# Fix: docs/dependency-tree.md's stale cert-manager version citation + mechanical guard

## What

`docs/dependency-tree.md`'s prose description of the `cert-manager` Helm
Application cited chart `v1.21.1` — but the live pin
(`gitops/platform/cert-manager.yaml`'s `targetRevision`) had already moved
to `1.21.2` on 2026-09-11 (per `docs/decisions/adr-0028-cert-manager-tls-lifecycle.md`'s
own Re-evaluation log and this run's own earlier `docs/dependency-register.md`
verification). Found via a full content-accuracy read of `docs/dependency-tree.md`.

## Why it matters

This is the exact same bug class `scripts/context-doc-version-sync-check.sh`
already exists to prevent — a hand-maintained prose doc citing a
component's version, going stale silently when the live pin moves
elsewhere without the doc being updated (previously found in
`docs/decisions/context.md` for Grafana/Pyroscope/KRO/ACK, 2026-07-28 and
2026-08-12). `docs/dependency-tree.md` simply hadn't had this guard
extended to it yet.

## Fix

1. **Fixed the citation**: `docs/dependency-tree.md`'s cert-manager line
   now says `v1.21.2`, matching the live pin.
2. **Mechanical guard (CLAUDE.md's bugfix-recurrence rule)**: extended
   `scripts/context-doc-version-sync-check.sh` — previously scoped only to
   `docs/decisions/context.md` — to also track `docs/dependency-tree.md`'s
   citations, reusing the same `check_one` framework rather than inventing
   a second mechanism. Added the cert-manager citation as this checker's
   first `docs/dependency-tree.md`-tracked entry. Updated
   `scripts/context-doc-version-sync-hook.sh`'s PostToolUse file-path
   filter to also fire on `docs/dependency-tree.md` edits (it previously
   only matched `docs/decisions/*` and `gitops/*`).
3. **Test coverage**: added a matching `docs/dependency-tree.md` +
   `gitops/platform/cert-manager.yaml` pair to both the `in-sync` and
   `drift` fixture trees (`tests/fixtures/context-doc-version-sync/`), so
   `tests/drift-adr-sync-checks.bats` now exercises real pass/fail
   detection for this checker again (previously it could only assert
   "always exits 0" since its tracked citations had all been removed
   along with their components, 2026-09-07). Added matching coverage to
   `tests/hook-scripts-context-doc-version-sync.bats` — a clean
   dependency-tree.md edit exits 0, a stale one exits 2.

## Verification

- `bash scripts/context-doc-version-sync-check.sh` — passes on the real
  repo post-fix, explicitly reports the new `cert-manager
  (dependency-tree.md)` check.
- Ran both fixture trees directly (`CONTEXTDOCCHECK_ROOT=.../in-sync` →
  exit 0; `CONTEXTDOCCHECK_ROOT=.../drift` → exit 1 with the expected
  message) before wiring them into bats.
- Ran the hook script directly against a synthetic stale
  `dependency-tree.md` fixture — confirmed exit 2 with the expected
  stderr message.
- `make ci` — full clusterless suite (bats, kustomize, kubeconform,
  terraform, ~40 drift-detector scripts) — green except the expected
  `docs-done-pr-link-check` placeholder failures.

## PR

_placeholder — backfilled after PR creation_
