# Re-verify every GHSA ID cited in docs/dependency-register.md (confirms the Harbor fabrication was isolated)

The previous cycle this run (PR #1484) found and fixed one fabricated GHSA ID
in `docs/dependency-register.md`'s Harbor row (`GHSA-56j8-6qr5-cg75`, which
doesn't exist). That raised an obvious follow-up question ADR-0004 demands be
closed rather than left open: was that fabrication isolated, or a symptom of
a broader pattern across the register's other cited advisories?

## What was checked

Extracted every unique GHSA ID currently cited anywhere in
`docs/dependency-register.md`:

```
grep -oE "GHSA-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}" docs/dependency-register.md | sort -u
```

15 unique IDs: `GHSA-366v-5xmx-36vh`, `GHSA-3fcv-jvfp-m4q9`,
`GHSA-3v3m-wc6v-x4x3`, `GHSA-4rvg-555h-r626`, `GHSA-56j8-6qr5-cg75` (the
already-fixed fabrication, PR #1484), `GHSA-5w68-77r2-r64c`,
`GHSA-72xg-3mcq-52v4`, `GHSA-79gf-7frw-68m9`, `GHSA-8rvj-mm4h-c258`,
`GHSA-gcjh-h69q-9w9g`, `GHSA-gx3x-vq4p-mhhv`, `GHSA-hj7x-hmf2-hc2p`,
`GHSA-j2g6-362q-6qc6`, `GHSA-prh4-vhfh-24mj`, `GHSA-r4pg-vg54-wxx4`.

Each of the 14 remaining IDs (excluding the already-fixed one) was verified
directly against GitHub's own advisory pages — a primary source, not a
search-engine summary (ADR-0004). A methodology note worth recording: three
of these (`GHSA-4rvg-555h-r626`, `GHSA-5w68-77r2-r64c`,
`GHSA-72xg-3mcq-52v4`) initially 404'd on the generic
`github.com/advisories/GHSA-xxx` URL, which looked at first like three more
fabrications. They are not — some real advisories aren't promoted to
GitHub's central/reviewed advisories database and only resolve at the
repo-specific path, `github.com/<org>/<repo>/security/advisories/GHSA-xxx`.
All three resolved cleanly there and match what the register currently
records. This 404-on-generic-URL behavior is a red herring, not a
fabrication signal by itself — the repo-specific path must be tried before
concluding an ID doesn't exist.

## Result

All 14 remaining IDs are real, existing GitHub advisories whose severity and
description match what's currently recorded in `docs/dependency-register.md`.
No further fabrications found. The Harbor row's `GHSA-56j8-6qr5-cg75` was an
isolated incident, not a pattern — closing the question the PR #1484 finding
raised.

## What was changed

No content in `docs/dependency-register.md` needed correction — this is a
confirm-clean verification pass, following this repo's established
"currency re-check — confirmed clean" pattern (e.g. the KEDA + Velero GHSA
sweep). This file is the record of the audit itself.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — no code, manifest, or
doc content changed; this PR only adds a docs/done/ record and a ROADMAP.md
pointer.

Found via a coverage/hardening sweep (executor STEP 6b fallback chain, this
run's twelfth consecutive cycle with a fully-gated "Now / next" lane) —
direct follow-up to the fabrication found in the immediately prior cycle,
closing the "is there more?" question rather than leaving it open.

## PR

https://github.com/tooming/k8s-anywhere/pull/1485 (auto/dependency-register-ghsa-audit-clean)
