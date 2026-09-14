# Industry digest — week 2026-W38

_Period: 2026-09-14 – 2026-09-20. Written 2026-09-14 (executor's
ARCHITECT-fallback cycle, `executor.prompt.md` STEP 6b — this run's fourth
cycle, reached with a fully exhausted "Now / next" lane: zero unchecked
ROADMAP items, zero open issues, zero un-RFC'd 🟡 items — after cycles 1–3
already shipped a DORA-metrics refresh
([#1588](https://github.com/tooming/k8s-anywhere/pull/1588)), a Traefik full
GHSA re-sweep finding 5 new advisories
([#1589](https://github.com/tooming/k8s-anywhere/pull/1589)), and an honest
`[Action needed]` record
([#1590](https://github.com/tooming/k8s-anywhere/pull/1590)). New file for a
new ISO week — 2026-W37 ([prior digest](2026-W37-digest.md)) was last
refreshed 2026-09-12, entirely within the prior week; per STEP 1c, a new week
gets a new file, not another in-place refresh of last week's._

---

## At-a-glance

- **This week's real finding: Traefik shipped 5 security fixes as `v3.7.13`
  (2026-09-04), and the fix is already flowing into an upcoming k3s
  release.** Cycle 2 of this run live-checked `traefik/traefik`'s advisories
  directly (not from memory) and found 5 new GHSAs published 2026-09-07 —
  GHSA-qqjf-53cj-pwvv (**Critical**, 9.1 CVSS, HTTP/3 NTLM connection
  reuse), GHSA-w4v4-9rw7-5326 (High, h2c request smuggling),
  GHSA-f52w-8j3h-j724 (High, rootless request-target routing bypass),
  GHSA-v67p-phpq-fc8x (High, header-trailer sanitization bypass), and
  GHSA-8fcf-v89g-xpg6 (Moderate, `BasicAuth` timing oracle) — all fixed in
  `v3.7.13`, all affecting this repo's running `v3.7.8` (bundled by the
  pinned k3s `v1.36.4+k3s1`). None of the 5 vulnerable code paths are used
  anywhere in this lab's `gitops/` (no HTTP/3, no `BasicAuth` middleware, no
  protected/unprotected router split, no proxy-header trust in ArgoCD's
  auth — confirmed directly), so no compensating control was needed. Full
  writeup:
  [docs/done/2026-09-14-traefik-ghsa-sweep-5-new-advisories.md](../done/2026-09-14-traefik-ghsa-sweep-5-new-advisories.md).
- **The fix is already inbound via k3s, still pre-release.** This cycle's
  fresh upstream check found `k3s-io/k3s`'s `v1.37.0-rc4+k3s1` (2026-09-09)
  release notes explicitly say "Updates Traefik to version 3.7.13" — the
  exact flip condition the Traefik register row and ADR-0040 already name
  ("re-check when k3s ships one"). `v1.37.0` remains at `-rc5` (2026-09-11),
  not a stable cut yet, so this repo's established bar (never adopt a
  pre-release) still holds — no bump this week — but the fix is now
  concretely one stable k3s release away rather than an open-ended wait.
  **For the architect: nothing to decide yet** (see below) — this is a
  currency fact to watch, not a decision point, until `v1.37.0` actually
  ships stable.
- **`docs/dora-metrics.md` refreshed** (cycle 1,
  [#1588](https://github.com/tooming/k8s-anywhere/pull/1588)): deployment
  frequency `97.67/week (1256 in 90d)` → `99.22/week (1276 in 90d)`, change
  failure rate `9.6%` → `9.4%` — the on-demand snapshot was 3 days/~20
  merges stale; not `make ci`-gated by design, so only a currency sweep
  surfaces it.
- **No open `adr-audit` issues, no un-RFC'd 🟡 ROADMAP items, no open PRs or
  issues of any kind** as of this cycle — confirmed directly
  (`list_pull_requests`/`list_issues`, both empty; `grep '^- \[ \]'
  ROADMAP.md`, zero matches). The backlog is genuinely exhausted, not just
  quiet.

---

## Lab stack

The lab's entire component set remains four always-on namespaces, nothing
on-demand (unchanged since 2026-09-07's simplification). Currency facts
below reflect this week's own live re-checks, not a cold read of the
register.

- **k3s** (`k3s-io/k3s`) — `v1.36.4+k3s1`, still the newest **stable** tag
  as of 2026-09-14. `v1.37.0-rc5+k3s1` (2026-09-11) is the latest
  pre-release; `-rc4` (2026-09-09) is the release that first bundles the
  fixed Traefik `v3.7.13` (see At-a-glance). ADR-0030 pins an explicit
  version per backend; no bump due until a stable `v1.37.0` cut.
- **ArgoCD** (`argoproj/argo-cd` chart via `argoproj/argo-helm`) — chart
  `10.9.0`, appVersion `v3.5.2`, both reconfirmed still current
  2026-09-14. A `v3.4.9` release landed today on the older 3.4.x line
  (patch backport, not a new latest) — `v3.5.2` remains the newest tag.
  Full GHSA re-check this week (10 advisories total now vs. 8 at the
  2026-09-03 full sweep; the 2 added — GHSA-h98r-wv3h-fr38,
  GHSA-rg3g-4rw9-gqrp — were already verified past-floor in cycle 2 of
  2026-09-13's run) — no third new advisory since.
- **Traefik** (`traefik/traefik`, bundled with k3s per ADR-0040) —
  `v3.7.8` (the version k3s `v1.36.4+k3s1` bundles). **5 new GHSAs found
  and analyzed this week** (see At-a-glance); fixed upstream in `v3.7.13`
  (released 2026-09-04) but not yet available via any stable k3s release.
  Full sweep + register update:
  [docs/done/2026-09-14-traefik-ghsa-sweep-5-new-advisories.md](../done/2026-09-14-traefik-ghsa-sweep-5-new-advisories.md).
- **cert-manager** (`cert-manager/cert-manager`) — `v1.21.2`, reconfirmed
  still the newest stable tag as of 2026-09-14. Same 3 advisories as the
  2026-09-03 full sweep — no new one this week.

Two more register rows track opt-in/bootstrap-only tooling: **Terraform/
Terragrunt** (`1.16.2`/`v1.1.4`, both reconfirmed current 2026-09-14 — no
bump due) and **Oracle Cloud Infrastructure** (opt-in cloud backend,
unchanged since its 2026-09-07 re-check).

CI-tool pins (not register-tracked, but re-checked this week for
completeness): `kustomize` `v5.8.1`, `kubeconform` `v0.8.0`, `tflint`
`v0.64.0` — all already the current latest stable release.

---

## Ecosystem

No adjacent-project findings this cycle — the sweep stayed scoped to this
lab's four pinned/bundled sources plus its CI tooling, per the same
established pattern as prior weeks.

---

## For the architect

**Nothing open this week.** No `adr-audit`-labeled issue is open, no 🟡
ROADMAP item lacks an RFC (zero 🟡 items exist anywhere in ROADMAP.md right
now, confirmed directly), and this week's one real upstream finding
(Traefik's 5 GHSAs) doesn't rise to an ADR-audit trigger: it's a
vulnerability disclosure against the already-chosen technology, fully
mitigated by this lab's current configuration (no vulnerable code path is
in use), not a "does the chosen technology still make sense" question.
ADR-0040's decision stands unchanged; no superseding ADR is warranted.

The one thing worth flagging for a **future** cycle, not this one: once k3s
`v1.37.0` ships stable (bundling Traefik `v3.7.13`, confirmed inbound via
`-rc4`'s release notes), that's this lab's routine minor-version bump
path (ADR-0030) — no new decision needed then either, just the normal
currency-bump flow once it's a real stable tag.

---

## Cadence

This is the eleventh entry produced under `architect.prompt.md` STEP 1c's
mandatory digest-write contract (see [2026-W37](2026-W37-digest.md)) and the
first **new-file** entry since 2026-W37's three same-week refreshes — a new
ISO week began between the prior digest's last refresh (2026-09-12) and this
one (2026-09-14). Reached via `executor.prompt.md` STEP 6b (cycle 4 of this
run) after PLANNER-fallback filler work (cycles 1–2) and an honest
`[Action needed]` record (cycle 3) already used up the "Now / next" and
dependency-currency lanes for this run.
