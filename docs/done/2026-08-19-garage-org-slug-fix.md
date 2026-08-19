# Fix the dead Garage GitHub org slug and pin a regression guard

JANITOR-fallback bounded cleanup (category 1: "a footgun that already bit
us"), reached via `executor.prompt.md` STEP 6b, cycle 17 this run, after
PLANNER (no ungroomed intake, no `docs/roadmap/incoming/` files, gap analysis
turned up nothing ROADMAP-scoped), ARCHITECT (zero unchecked 🟡 items to RFC),
and the "Now / next" lane's own re-confirmation (still gated: two GitLab→
Forgejo migration items per their own investigation notes, and the capstone
`Deployment` removal on issue #633 — re-checked, `updated_at` unchanged since
2026-08-17) all found nothing new.

## The footgun

While independently re-verifying Garage's upstream security-advisory
history (the next stalest entry in `docs/dependency-register.md`'s "Last
reviewed" column, 2026-07-28), a direct fetch of
`github.com/Deuxfleurs/garage/security/advisories` returned a plain HTTP 404
with no redirect. The real GitHub org is `deuxfleurs-org`
(`github.com/deuxfleurs-org/garage`, confirmed reachable via `git
ls-remote`) — `Deuxfleurs` (and `deuxfleurs`, missing the `-org` suffix) has
never been a valid org for this project on GitHub.

This wasn't just a stale doc cross-reference: `routines/architect.prompt.md`
STEP 1 hardcodes the identical wrong slug (`deuxfleurs/garage`) into the
architect routine's own weekly upstream-release check instruction (`gh
release list --repo deuxfleurs/garage`). Every past architect run following
that line literally would have queried a nonexistent repository rather than
checking Garage's real release history — a silent, self-inflicted blind spot
in this repo's own currency-audit tooling.

It was invisible to `make ci`'s `markdown-links-check` by design: that check
only resolves proper `[text](path)` markdown links, and explicitly excludes
external `http(s)://` URLs as "a reachability check on external URLs is a
different, network-dependent problem" (its own header comment). The bad slug
here was bare text in a table cell and a prompt-file list item, not a
markdown link at all — doubly outside that check's scope.

## The fix

- `docs/dependency-register.md`'s Garage row: `github.com/Deuxfleurs/garage`
  → `github.com/deuxfleurs-org/garage`, with a "Last reviewed" cell
  documenting the org-slug bug and today's re-verification against the
  correct URL (`v2.3.0` still the newest stable tag, zero published
  advisories — same conclusion the 2026-07-28 audit reached, now grounded in
  a URL that actually resolves).
- `routines/architect.prompt.md` STEP 1: `Garage: deuxfleurs/garage` →
  `Garage: deuxfleurs-org/garage`. No apply step needed — per
  `CLAUDE.md`'s routines pointer-architecture section, only `routines.yaml`
  needs the `RemoteTrigger update` dance; a `routines/*.prompt.md` edit is
  live the moment it merges, and the executor may edit any fallback role's
  prompt file directly.
- `docs/decisions/adr-0002-garage-not-minio.md`: a new dated
  `## Re-evaluation log` entry recording the trigger, the finding, and the
  keep-the-pin/fix-the-slug decision with an explicit flip condition.
- `tests/dependency-register.bats`: a new pinned-value regression guard
  asserting `github.com/deuxfleurs-org/garage` is present in both
  `docs/dependency-register.md` and `routines/architect.prompt.md`, and that
  the dead `Deuxfleurs/garage` / `deuxfleurs/garage` slug (any casing,
  missing the `-org` suffix) never reappears in either file — mirrors this
  repo's existing pinned-tag / no-floating-tag guard convention (e.g.
  `tests/inkless.bats`).

`make ci` (full suite, bats included) is green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1264
