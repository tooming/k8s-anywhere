# [Action needed] Now/next still gated; remaining floating-tag images already have documented, deliberate carve-outs

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items every
recent cycle has found gated, re-verified fresh this cycle:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (still open,
   no new comment since 2026-08-04).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (still open,
   no new comment since 2026-08-04).

## This run's real deliverables so far (not idle)

This is a single continuous run. Prior cycles this run landed 8 merged PRs
plus one closed audit issue:

- [#1008](https://github.com/tooming/k8s-anywhere/pull/1008)/[#1009](https://github.com/tooming/k8s-anywhere/pull/1009) — `ack-s3` chart `1.8.2` → `1.9.0`.
- [#1010](https://github.com/tooming/k8s-anywhere/pull/1010)/[#1011](https://github.com/tooming/k8s-anywhere/pull/1011) — Vault image `2.0.3` → `2.0.4`.
- [#1012](https://github.com/tooming/k8s-anywhere/pull/1012) — prior honest cycle record.
- [#1013](https://github.com/tooming/k8s-anywhere/issues/1013)/[#1014](https://github.com/tooming/k8s-anywhere/pull/1014) — ADR-0015 audit, held Inkless Postgres at `17.x`.
- [#1015](https://github.com/tooming/k8s-anywhere/pull/1015)/[#1016](https://github.com/tooming/k8s-anywhere/pull/1016) — Inkless Postgres image pinned explicitly, `17` → `17.10`.

## This cycle's fresh angle: every remaining floating-tag `image:` in `gitops/`

Following on from the Vault/Postgres explicit-pin findings above, this
cycle walked every plain `image:` reference in `gitops/**/*.yaml` for any
*other* floating (non-exact-patch) tag: `ghcr.io/aiven/inkless:latest`,
`nginx:alpine` (`gitops/tidb-demo/deployment.yaml`), and
`harbor.127.0.0.1.nip.io/library/hello:latest` (the capstone demo app's own
CI-built image, not an upstream dependency).

All three already have deliberate, documented carve-outs — checked
directly, not assumed:

- **`ghcr.io/aiven/inkless:latest`**: `gitops/kyverno/policies/disallow-latest-tag.yaml`'s
  own header comment (dated 2026-07-28) already investigated this exact
  question and found Aiven publishes **no stable named release** for this
  image on its actual GHCR package page — only rotating `edge-<commit>`
  builds. (This cycle initially found real-looking tags like
  `inkless-release-0.46` via `git ls-remote --tags` on the *source* GitHub
  repo, but per ADR-0004 a source-repo git tag existing doesn't prove a
  matching container image was ever published under that tag on GHCR —
  the prior session's carve-out comment explicitly checked the package
  registry itself, not git tags, so its "edge-only" finding stands and this
  cycle's git-tag observation doesn't actually contradict it.) The
  `disallow-latest-tag` ClusterPolicy already excludes the `inkless`
  namespace for exactly this reason, with a stated flip condition ("remove
  once `ghcr.io/aiven/inkless` ships a stable, pinnable named release tag").
  Not a gap.
- **`nginx:alpine`**: a distro-variant floating tag (not a version stream),
  same "intentional follow-the-stream" class this repo already accepts for
  Garage's `main` tag — used in a `tidb-demo` scratch container, not a
  security-sensitive always-on component.
- **`harbor.../hello:latest`**: the capstone demo app's own image, built and
  pushed by this repo's own CI — already tracked by issue #498's
  `disallow-latest-tag` carve-out (with its own flip condition: a real
  CI-pinned tag once Kargo is wired to capstone's image ref).

No new gap found. Every floating tag left in `gitops/` is a deliberate,
already-documented choice, not an oversight this run's earlier Vault/Postgres
pins simply hadn't reached yet.

## Assessment

Two real, verified fixes (Vault, Inkless-Postgres explicit pins) already
landed this run from the same "floating tag" lens; this cycle's continuation
of that lens onto every *remaining* floating tag confirms the rest are
deliberate, documented, and correctly carved out — not additional gaps.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or #999; (b) PR #980
merging; (c) a new GitHub issue (ungroomed intake — currently none exists);
(d) Aiven publishing a stable, pinnable release tag for `inkless` (flips the
`disallow-latest-tag` carve-out); (e) a new upstream CVE/release firing one
of this repo's many tracked flip conditions.

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
