# [Action needed] Now/next still gated; ADR audit-gap sweep clean, DORA metrics refreshed

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, 2 comments each, no new confirmation since the
verification-command fixes posted earlier today.

## What this cycle already did

Merged [#896](https://github.com/tooming/k8s-anywhere/pull/896): refreshed
`docs/dora-metrics.md` (CHARTER Objective O7), which was 9 days stale during a
period of unusually high merge velocity. Deployment frequency 47.67 → 65.16
deployments/week, change failure rate 7.8% → 6.8%, both recomputed from real
git history (lead time / time-to-restore remain "insufficient data" — no `gh`
CLI in this sandbox, not fabricated per ADR-0004).

## This cycle's fresh angle

An **architect-flavored ADR audit-gap sweep**, not yet attempted earlier this
run: grepped every ADR for a `## Re-evaluation log` section and found 10 of 30
lack one — `adr-0001`, `adr-0003`, `adr-0004`, `adr-0005`, `adr-0007`,
`adr-0010`, `adr-0011`, `adr-0025`, `adr-0026`, `adr-0027`. Filtered out the
two already-`Superseded` ADRs (`adr-0010` Redis→Valkey, `adr-0011`
Artifactory→Harbor — dead decisions, a re-eval log on a superseded ADR would
be meaningless) and the four short foundational/invariant ADRs (`adr-0001`,
`adr-0003`, `adr-0004`, `adr-0005` — 15–26 lines each, encoding cross-cutting
principles rather than a reversible technology pick with a flip condition;
the Re-evaluation log pattern doesn't fit that shape).

That left `adr-0007` (off-cluster Garage tfstate backend), `adr-0025`
(free/OSS tiers only), `adr-0026` (cloud-agnostic infrastructure), and
`adr-0027` (Oracle Always Free first cloud backend) as real candidates. Did a
full currency check on `adr-0027` — the most externally-dependent and
time-sensitive of the four (it cites a specific Oracle Always Free capacity
figure and a since-observed `500 Out of host capacity` constraint) — against
`infra/live/README.md`'s living Status table (updated 2026-07-15) and the
`oracle-k3s-cluster` module. Every fact ADR-0027 states is still accurate:
the 2 OCPU/12 GB Ampere A1 allocation, the second off-cluster Garage instance
for tfstate (not the same VM, avoiding the circularity an earlier draft had),
and the "not yet verified: k3s compute instance launch, blocked by transient
OCI capacity" status all match `infra/live/README.md` word-for-word on the
facts. No drift found — nothing to fix, and no new `## Re-evaluation log`
section added, since inventing one to record "still true" without the
architect's own dated-audit convention (`docs/decisions/adr-0002.md`'s "audit
#\<issue\>" citation style) would be a lower-fidelity version of that pattern
built by the wrong role. Flagging `adr-0007`/`adr-0025`/`adr-0026` as
un-audited-but-plausibly-fine for the architect routine's own pass, not
claiming to have closed that gap here.

With the ADR audit-gap angle now also walked and confirmed clean, every
fallback-chain stop tried by this run today (janitor script-dedup, ROADMAP
doc-precision, doc-drift ×4, CHARTER O2 namespace-coverage audit, issue
triage, a full local `make ci` run, DORA metrics refresh, and now this ADR
audit-gap sweep) has turned up real work exactly once out of the last two
cycles (the DORA refresh) — the repo is, genuinely, this clean right now.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
