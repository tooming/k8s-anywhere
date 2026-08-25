# CHARTER.md: cross-reference the GitLab-vs-Forgejo bootstrap gap

(CHARTER **Core Values** §"Everything as code" + ADR-0004 (no fabricated content);
executor-fallback stale-doc-reference sweep 2026-08-25, reached via
`executor.prompt.md` STEP 6b — this run's "Now / next" lane was fully gated (the two
sequentially-blocked GitLab→Forgejo migration items plus the legacy capstone
`Deployment` removal, still gated on issue #633 — re-checked, no new comment since
2026-08-17) and PLANNER/ARCHITECT fallback passes found no ungroomed issues and no
un-RFC'd 🟡 items (only 2 open issues exist, both standing maintainer-confirmation
gates, #633/#1229). UPGRADE-DRAFTER-fallback currency spot-checks (TiDB Operator
`1.6.6`, TiDB `v8.5.7`, Loki `3.7.6`, Pyroscope chart `2.2.1`) all reconfirmed already
current — no gap. DOC-DRIFT-AUTHOR-fallback found `make ci`'s drift checks fully clean
locally. TRIAGER-fallback found nothing to triage. **No prerequisites — executor may
pick up immediately.**

Five prior cycles across 2026-08-17–2026-08-20 (PRs #1289, #1292, #1293, #1294, and
one more) added a "GitLab vs. Forgejo, as of 2026-08-17" caveat blockquote to every
doc that describes `make up`'s literal bootstrap sequence — a fresh bootstrap still
provisions GitLab (ADR-0033/ADR-0035, unchanged), but the currently-running lab's
ArgoCD was separately re-pointed at Forgejo directly on the live cluster (PR #1205)
without `make up`'s script being updated to match: README.md, `docs/00-architecture.md`,
`docs/DR.md`, `docs/dependency-concentration.md`, and `docs/platform-products.md`.
**CHARTER.md's own "Target end-state" section — the "Always-on core" and "Capstone"
bullets, both still naming GitLab as the git source / CI — never received this caveat**,
even though it's the same class of architecture-description doc as the five already
fixed (confirmed directly: `grep -n "GitLab|Forgejo" CHARTER.md` showed exactly these
two un-caveated mentions, nothing else).

Added the identical caveat blockquote shape used in the five prior fixes (same title,
same "what `make up` still does" vs. "today's steady-state" framing), placed once
after the "Always-on core" bullet (which now cross-references the Capstone bullet
below it) rather than repeating it at both — mirroring how the `docs/platform-products.md`
fix placed one caveat near the file's first GitLab mention instead of annotating every
occurrence. Left `docs/incident-log.md`'s historical GitLab mentions untouched — those
describe what was actually true at the time each incident happened and must not be
rewritten (ADR-0004: don't retroactively alter a historical record).

No `gitops/` manifest change; behavior-preserving (prose-only). `make ci` stays green
— all local drift/link checks pass, including "every internal markdown link resolves"
(the five new relative links to README.md / docs/00-architecture.md / docs/DR.md /
docs/dependency-concentration.md / docs/platform-products.md all resolve).

## PR

https://github.com/tooming/k8s-anywhere/pull/1309
