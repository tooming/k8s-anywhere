# [Action needed] Now/next still gated; remaining low-priority component sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (fifth cycle of 2026-07-26): all three still open, zero comments.

## This cycle's fresh angle

Closed out the "remaining unswept components" list explicitly flagged as
follow-up in
[`2026-07-26-action-needed-cycle3-harbor-kafka-gitlab-recheck.md`](2026-07-26-action-needed-cycle3-harbor-kafka-gitlab-recheck.md):
`kro`, Grafana Alloy, Pyroscope, `node_exporter`, and `moto`.

**One false-positive lead caught and discarded — worth recording explicitly.**
A search for "Grafana Alloy CVE 2026" surfaced a list of seven CVE IDs
(CVE-2026-24051, -25934, -26958, -32287, -33186, -33762, -34165) with fixed
versions quoted as `1.13.2-r0`/`1.14.1-r0`/`1.14.1-r1` — version strings
carrying the `-rN` package-revision suffix, which is a Chainguard/Wolfi
container-image packaging convention, not upstream Grafana Alloy's own
release versioning. Checked directly: `github.com/grafana/alloy`'s own
Security Advisories page has **zero published advisories** — none of those
seven CVE IDs are associated with the actual upstream project at all. This is
the same kind of red herring a prior cycle already caught and discarded for
Alloy (`2026-07-25-action-needed-cycle3-dependency-sweep-exhausted.md`'s
"lookalike `alloy-*` tags" note) — recording it explicitly again here so a
future cycle doesn't waste time re-chasing the same dead end from a fresh
search.

**Remaining components, all clean:**

| Component | Pinned version | CVE checked | Verdict |
|---|---|---|---|
| `kro` | chart `0.9.2` | CVE-2025-48710 (confused-deputy RCE via arbitrary container images in `ResourceGraphDefinition`, fixed 0.2.1) — a 2025 CVE, not 2026, but checked for completeness since it's the only kro advisory found | current — `0.9.2` is far above the `0.2.1` fix; no 2026 kro CVE exists |
| Grafana Alloy | chart `1.10.1` | see false-positive note above; no real advisory found | not applicable — no genuine upstream CVE exists to check against |
| Pyroscope | chart `2.2.0` (appVersion confirmed `2.2.0` via the chart's own GitHub release notes) | CVE-2026-25679 (Tencent COS backend `secret_key` disclosure via the Pyroscope API, fixed 1.15.2/1.16.1/1.17.0) | current — `2.2.0` postdates the entire 1.x fix-version range |
| `prometheus-node-exporter` | chart `4.56.1` | searched; only match found (CVE-2026-44902) is an unrelated OpenTelemetry JS Prometheus *exporter* library, not `node_exporter` itself | not applicable — no real node_exporter CVE surfaced |
| `motoserver/moto` | image `5.2.2` | searched; no moto-specific CVE surfaced (only unrelated AWS-LC/AWS bulletins) | no finding either way — not a confirmed gap |

No actionable version gap found on any of the five components. This closes
out every component flagged across this run's five CVE-research cycles today
(PRs #729, #730, #731, plus this one) — the full always-on + on-demand
dependency set has now had a CVE-specific pass, not just a version-currency
one.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of any
size.

This note is this cycle's honest record — completing the CVE-research lens's
component list rather than repeating it, plus catching and documenting a
recurring false-positive search pattern — not a stopping point. The run
continues to the next cycle per `executor.prompt.md` STEP 8.
