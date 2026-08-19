# [Action needed] Now/next still gated; Velero and Argo Rollouts confirmed safe (cycle 16)

**Date:** 2026-08-19
**Cycle:** 16th cycle this run

## What was tried this cycle

Continued the direct security-advisory-page sweep against two more
Objective-O1 always-on-next-wave components:

- **Velero** (chart `12.1.0`, appVersion `1.18.1`) — found
  **GHSA-j2g6-362q-6qc6**, a Moderate path-traversal-via-backup-tarball
  advisory published the **same day** as this audit (2026-08-19), affecting
  `<1.18.1`. This lab's pin is exactly `1.18.1` — the advisory's own
  "Patched versions" field said "None" (drafted before the fix shipped),
  so this was independently cross-checked against `v1.18.1`'s real
  changelog directly rather than trusted at face value: the changelog
  confirms "Add check for file extraction from tarball" (PR #9661) landed
  in that exact release. RFC #617's chart-major-jump decision (2026-07-20,
  made purely for schema-currency reasons, no CVE involved at the time)
  happened to land the lab a month ahead of this brand-new CVE.
- **Argo Rollouts** — checked
  `github.com/argoproj/argo-rollouts/security/advisories` directly: **zero
  published advisories exist for this repository at all.**

`docs/dependency-register.md`'s Velero and Argo Rollouts rows updated, and
`docs/decisions/adr-0021-velero-backup-restore.md` gets a full
Re-evaluation log entry given how time-sensitive this finding is (same-day
GHSA, stale "no patch" advisory metadata cross-checked against the real
release).

## What's blocked

Unchanged: the "Now / next" lane holds the same three items (two
GitLab→Forgejo migration items un-picked-up per their own investigation
notes; capstone `Deployment` removal gated on issue #633, still open, no
new confirmation).

## Why this is the honest deliverable

A genuinely time-sensitive finding (a same-day CVE, verified past a stale
advisory field by checking the real release changelog) plus one more
component confirmed to have no CVE history at all. No code shipped this
cycle. Not a stopping point — the run continues from STEP 1 per STEP 8.
