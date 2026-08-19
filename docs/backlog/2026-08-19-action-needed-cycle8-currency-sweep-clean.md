# [Action needed] Now/next still gated; targeted currency sweep on the stalest-reviewed deps clean (cycle 8)

Autonomous scheduled executor run, cycle 8 of this session (cycles 1-7
already landed PRs #1268-#1274). This cycle picked a different, targeted
angle: instead of a broad sweep or another gate re-check, read
`docs/dependency-register.md`'s "Last reviewed" column to find the
**stalest-reviewed** components with their own dedicated ADR currency
history, and re-verified each one directly against upstream.

## Now/next re-checked (unchanged)

All three items (GitLab→Forgejo rename, GitLab decommission, capstone
`Deployment` removal gated on issue #633) re-confirmed gated — same
conclusion as cycles 1 and 7, no new information since.

## Targeted currency checks (verified directly, not assumed — ADR-0004)

- **Harbor** (chart pin `1.19.2`, register last reviewed 2026-08-03 — the
  stalest specific per-component date in the whole table). Fetched
  `github.com/goharbor/harbor-helm/tags` directly: `v1.19.2` (Aug 3, 2026)
  is still the newest tag, 16 days later. **No currency gap.**
- **Kiali** (chart pin `2.30.0`, register last reviewed 2026-08-04).
  Fetched `github.com/kiali/helm-charts/tags` directly: `v2.30.0` (Aug 3,
  2026) is still the newest stable tag. **No currency gap.**
- **TiDB Operator** (pin `1.6.6`, register last reviewed 2026-08-12,
  ADR-0031 holds it at the `1.6.x` line deliberately). Fetched
  `github.com/pingcap/tidb-operator/tags` directly: `v1.6.6` (Aug 11, 2026)
  is still the newest `1.6.x` tag (`v1.7.0-alpha.*`/`v2.2.0-alpha.*` exist
  but are out of ADR-0031's scope). **No currency gap.**

One dead-end worth recording so a future cycle doesn't repeat it: an
initial `WebFetch` against `github.com/goharbor/harbor-helm/releases/latest`
returned a hallucinated `v2.15.2`/`2024` result (wrong repo's version scheme,
wrong year) — caught only by cross-checking against the real `/tags` listing
page directly. Treat single-page `WebFetch` release-note summaries as
provisional; a tag-list cross-check is what actually confirmed currency here.

## k3s / ADR-0030 register-row check (verified correct-as-is, not a bug)

Investigated whether `docs/dependency-register.md`'s k3s row (cites
ADR-0027, "not dated in ADR") is stale, since the *actual* k3s
version-pinning history and Re-evaluation log lives in
[ADR-0030](../decisions/adr-0030-pin-k3s-version-explicitly.md) (currently
kept at `v1.36.3+k3s1`, last re-evaluated 2026-08-05) — a different ADR
than the one the register row cites. **This is intentional, not drift**:
the register's own Scope note (lines 38-47) explicitly excludes ADR-0030
from the table as a "policy ADR enforced via an already-listed tool" (the
same documented shape as ADR-0016/Cilium), so the k3s row correctly cites
ADR-0027 (the backend-choice ADR, which genuinely has no Re-evaluation log
of its own) rather than ADR-0030. No edit made — would have fought the
file's own documented convention.

## Why an honest record, not manufactured work

Three real dependency-currency checks and one register-convention
double-check all came back clean/correct-as-is this cycle. Per ROADMAP
rule #9 / `executor.prompt.md` STEP 6b: an honest record beats forcing an
unneeded edit. The run continues per STEP 8 — not a stopping point.

## PR

(filled in once the PR is opened)
