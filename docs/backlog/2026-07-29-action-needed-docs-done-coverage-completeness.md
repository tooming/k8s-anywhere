# [Action needed] Now/next still gated; docs/done coverage completeness check (3 near-misses caught, all false positives)

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#866](https://github.com/tooming/k8s-anywhere/pull/866)
(cert-manager/KEDA sync-wave dependency chain check).

## This cycle's fresh angle

Checked whether every `[x]`-checked ROADMAP item with a `(auto/<slug>)`-style
branch reference has a corresponding `docs/done/` record — the reverse of
the usual drift check (this verifies the *record* exists, not just that
the *code* landed). Wrote a script that correctly parses each ROADMAP item
as a block (not a single-line regex, which under-matched badly on the
first attempt) and cross-references 111 checked items with branch slugs
against the 200+ files in `docs/done/`.

**Three items initially looked unmatched** by a substring search:
`auto/cilium-cve-bump-1-17-18`, `auto/kargo-cve-bump-1-6-4`,
`auto/kyverno-policies`. Checked each individually before reporting — all
three **do** have a real record, just under a filename that doesn't
literally contain the branch slug as a substring:

- `auto/cilium-cve-bump-1-17-18` → `docs/done/2026-07-18-cilium-cve-bump.md`
  (title: "Bump Cilium `1.16.6` → `1.17.18`").
- `auto/kargo-cve-bump-1-6-4` → `docs/done/2026-07-18-kargo-cve-bump-and-fixes.md`
  (title: "Bump Kargo `1.2.3` → `1.6.4` ...").
- `auto/kyverno-policies` → `docs/done/legacy-kyverno-initial-clusterpolicies-validate-mutate-verifyimages.md`
  (a pre-dated-naming-convention "legacy-" file whose own body text ends
  literally `(auto/kyverno-policies PR #TBD)`).

**Conclusion: zero real gaps.** Every checked ROADMAP item has its
`docs/done/` record; the mismatches were purely a filename-substring
search limitation, not missing documentation.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct completeness
check (docs/done coverage, the reverse direction of the usual drift check)
that caught and resolved three of its own near-miss false positives before
writing anything wrong into the record. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
