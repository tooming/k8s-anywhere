# [Action needed] Now/next still gated; .gitignore effectiveness audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21 (8+
days; already flagged to the maintainer via a proactive notification in the
prior cycle).

## What this cycle already did

Merged [#844](https://github.com/tooming/k8s-anywhere/pull/844)
(ExternalSecret refresh-interval consistency audit).

## This cycle's fresh angle

A different secret-hygiene check than the earlier content-grep sweep (which
scanned tracked file *contents* for hardcoded credential-looking strings):
this cycle checked whether `.gitignore` itself is both comprehensive and
**actually effective** — i.e., whether any file `git ls-files` currently
tracks matches a sensitive-file pattern that should have been excluded.

- `.gitignore` covers: Terraform/Terragrunt state and cache
  (`*.tfstate*`, `.terraform/`, `.terragrunt-cache/`), kubeconfig/`.env`/
  secrets directories, `*.pem`/`*.key` material, and GitLab's bind-mounted
  runtime data/TLS/token files.
- Cross-checked `git ls-files` against the same sensitive-pattern set
  (`.tfstate`, `.tfvars`, `.terraform/`, `kubeconfig`, `.pem`, `.key`,
  `id_rsa`, `.env`) — **zero matches** (excluding known-safe test/fixture/
  example files, of which there were none to exclude either). Nothing
  sensitive has slipped through despite whatever history this repo has
  accumulated.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633
(flagged, still awaiting response); (b) a new upstream CVE/release firing a
tracked ADR flip condition; (c) a new GitHub issue of any size (ungroomed
intake).

This note is this cycle's honest record — a genuinely distinct check
(`.gitignore` effectiveness, not just its presence/content) complementary
to but distinct from the earlier content-based secret-scan sweep. The run
continues to the next cycle per `executor.prompt.md` STEP 8; this is not a
stopping point.
