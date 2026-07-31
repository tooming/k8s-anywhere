# Fix stale merge-gate claim + retired autonomy-tier label in .github/CODEOWNERS

`.github/CODEOWNERS`'s header comment (untouched since the file's original creation,
before either governance change) said: "(with branch protection) requires their
review before merge. This is what stops an agent PR from merging without a human
owner's approval." This directly contradicts current `docs/WAYS-OF-WORKING.md`:

- §4: branch protection on `main` was removed 2026-07-13 — "No CODEOWNERS review
  required" is stated explicitly as one of the things GitHub no longer enforces.
- §0.1 (adopted 2026-07-14): any agent may self-merge its own PR with no human
  approval gate at all, including PRs touching CODEOWNERS-listed governance paths.

The comment described a mechanism (CODEOWNERS-gated review blocking agent merges)
that has not existed for over two weeks. Separately, the file's "🔴 High-trust paths
(Red tier)" section header referenced the Green/Yellow/Red autonomy-tier model that
§0.1 explicitly says was superseded — that model no longer exists in this repo's
governance, yet the file still labeled paths by it.

## Fix

Rewrote the header comment to state plainly that this file is ownership routing/
attribution metadata only, not a merge gate, citing WAYS-OF-WORKING.md §0.1/§4.
Replaced the "🔴 High-trust paths (Red tier)" section header with a
tier-model-free description ("ownership attribution only, not a merge gate"). Left
every actual path/owner assignment unchanged — this is a comment-only fix, no
functional CODEOWNERS routing behavior changes (it was already non-enforcing).

No topology/decision change. Sixth fix in this run's doc-drift cross-check sweep
(Velero namespace count #929, Kyverno replica count #930, CHARTER O3 count #932,
ADR-0024 status header #936, WAYS-OF-WORKING chore/* prefix #941).

`make ci` passes (2345 assertions, 0 failures).

## PR

https://github.com/tooming/k8s-anywhere/pull/943
