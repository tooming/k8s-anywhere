# [Action needed] Now/next still gated; ADR-citation integrity sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#833](https://github.com/tooming/k8s-anywhere/pull/833) (TODO sweep +
live ArgoCD `latest`-tag upstream re-verification).

## This cycle's fresh angle

ROADMAP.md's own DORA-mapping item (`docs/dora-resilience-mapping.md`, RFC
#586) explicitly notes: `make markdown-links-check` catches broken relative
*links* but not a wrong ADR *number* cited in prose — that has to be checked
by hand. No prior `docs/backlog/` note has done this repo-wide, so this cycle
did:

1. Extracted every `ADR-NNNN` citation across all tracked `*.md` files
   (32 distinct citation numbers found) and cross-referenced each against the
   real `docs/decisions/adr-*.md` file list (30 real ADRs, 0001–0030, no
   duplicate numbers). Two citation numbers had no matching real file:
   - `ADR-0099` — every occurrence is inside `tests/fixtures/*/docs/decisions/
     adr-0099-widget.md`, explicitly labeled `(fixture)` — intentional test
     data, not a real citation.
   - `ADR-0031` — the sole occurrence (`docs/done/2026-07-19-charter-adr-count-
     drift.md:15`) is prose discussing *why a hypothetical future numbering
     scheme* would eventually drift, not a claim that ADR-0031 currently
     exists. Read in context; not a broken citation.
2. Spot-checked ~40 citations that carry an inline topic hint (e.g. "ADR-0002
   (Garage)", "ADR-0008 — Envoy Gateway") against each real ADR's actual
   subject: every sampled citation's stated topic matches its file's real
   subject. No mismatched/stale citation found (e.g. no case of "ADR-0018"
   being cited as something other than Valkey, or "ADR-0016" as something
   other than default-deny NetworkPolicy).

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct check (ADR
citation-number + topic-consistency integrity, explicitly named as a gap
`markdown-links-check` doesn't cover, not a repeat of any prior cycle's
technique). The run continues to the next cycle per `executor.prompt.md`
STEP 8; this is not a stopping point.
