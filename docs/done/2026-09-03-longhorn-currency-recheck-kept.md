# Longhorn currency re-check — `v1.12.1` now stable, ADR's own flip condition still not triggered, kept at `1.11.3`

Continuing this run's coverage/hardening sweep (ROADMAP rule #9's fallback
chain) after the "Now / next" lane was re-confirmed fully gated, checked
every pinned chart's real upstream currency once more. Found Longhorn's
`1.12.x` line — the line ADR-0013's 2026-07-18 entry deliberately stayed one
minor line behind — went stable in the meantime.

## What was checked

Directly against live sources (ADR-0004), not assumed:

- `github.com/longhorn/longhorn/releases`: `v1.12.1` released **2026-08-14**
  (real release notes: V2 Data Engine fast volume cloning + experimental
  storage sharding, extended instance-manager mTLS, new internal
  `NetworkPolicy` rules, and an explicit breaking change — legacy V2
  linked-clone volumes from `v1.12.0` or earlier are deprecated).
- Cross-verified the tag is real (not a hallucinated summary) via
  `raw.githubusercontent.com/longhorn/longhorn/v1.12.1/deploy/
  longhorn-images.txt`, which resolves and lists real `longhornio/*:v1.12.1`
  image tags — same "does the raw file 404 or not" verification method used
  for the Vault/ADR-0037 tag check earlier this run.

## Decision: kept at `1.11.3` — an ADR-guarded case, not a currency gap

ADR-0013's own 2026-07-18 Re-evaluation log entry pins `1.11.3` **on purpose**,
deliberately staying one minor line behind `1.12.x` because that line's V2
Data Engine GA is "a bigger behavioral surface change than a routine currency
bump warrants." Its flip condition is narrow: re-check when `1.11.x`
approaches its own EOL window, or a CVE is filed against the current pin.
Neither has fired — `1.11.x` is ~7 weeks into its support window, and the
2026-08-19 GHSA sweep already found no CVE against `1.11.3`. `v1.12.1`'s own
release notes (including a real breaking change) reinforce rather than
undercut the original reasoning.

Bumping here without either flip condition firing would have silently
contradicted a binding, reasoned architect decision — exactly what CLAUDE.md's
"never silently violate an ADR" rule exists to prevent. Recorded the check
directly in ADR-0013's Re-evaluation log instead of bumping, so the "still
current, still deliberately behind" state has a fresh, verified timestamp.

## What changed

- `docs/decisions/adr-0013-longhorn-block-storage.md`: new Re-evaluation log
  entry.
- `docs/dependency-register.md`: Longhorn row updated.

No `gitops/` change (correctly — this is a "confirmed no action needed"
finding). `make ci` passes green.

## PR

(filled in after PR creation)
