# [Action needed] Now/next still gated; secrets-hardening sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, still zero comments.

## This cycle's fresh angle

A fourth distinct lens: a security-hardening sweep for plaintext secrets or
hardcoded credentials committed to `gitops/`/`infra/`, rather than another
version/coverage/precision check.

- `grep -rln "^kind: Secret$" gitops/` — zero matches. Every secret-shaped
  object in the repo is an `ExternalSecret` (Vault-backed), consistent with
  the CHARTER Goals' secrets-flow design (Vault → External Secrets →
  workload) — no plaintext `Secret` manifest is committed anywhere.
- Broader credential-pattern grep (`password:`, `secretKey:` with an
  inline-looking value, AWS-style access-key prefixes) across
  `gitops/`/`infra/` — one hit, `gitops/platform/harbor.yaml`'s
  `existingSecretAdminPassword: harbor-admin-creds`, which is a reference to
  a Secret *name* (the actual value lives in the referenced
  `ExternalSecret`-managed Secret), not an inline credential. No real leak.

Conclusion: this lens also comes up clean.

## Prior cycles this run (context, not idle)

PR #672/#673/#674 (Envoy Gateway v1.8.3 bump, full RFC→plan→build loop),
PR #675 (upstream-version sweep, empty), PR #676 (dashboard-coverage sweep,
empty), PR #677 (CHARTER-precision sweep, empty).

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue.

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8.
