# Traefik full GHSA re-sweep — 5 new advisories since the 2026-09-06 sweep, none exploitable in this lab's config, no fix available yet

Found live 2026-09-14 (STEP 6b PLANNER-fallback filler, ROADMAP rule #9 — a
second cycle in this run, after the "Now / next" lane was found completely
empty and the on-demand DORA-metrics currency gap was already closed this
run in [#1588](https://github.com/tooming/k8s-anywhere/pull/1588)). Extending
that same currency-sweep instinct to a fresh angle: `docs/dependency-register.md`'s
Traefik row's **last full GHSA sweep** was 2026-09-06 (the 2026-09-11 entry
only re-checked version currency, "no new GHSA published... since the
2026-09-06 full sweep" — an assumption, not a live re-check) — 8 days old,
the longest-since-last-full-sweep of the four pinned/bundled sources (mirrors
cycle 3's ArgoCD full-sweep pattern from 2026-09-13's run). Live-checked
`traefik/traefik`'s published GitHub security advisories directly
(`github.com/traefik/traefik/security/advisories`, not from memory, ADR-0004)
rather than trusting the "no new GHSA" assumption.

## What was found

**5 new advisories, all published 2026-09-07** (one day after the last full
sweep) — none were part of the 9 checked in
[docs/done/2026-09-06-traefik-full-ghsa-sweep.md](2026-09-06-traefik-full-ghsa-sweep.md):

| Advisory | CVE | Severity | Affected (tops out at) | Fixed | Requires (in this lab) |
|---|---|---|---|---|---|
| GHSA-qqjf-53cj-pwvv | CVE-2026-88007 | **Critical** (9.1) | `3.0.0`-`3.7.12` | `3.7.13` | HTTP/3 entry point + backend using connection-bound NTLM/Negotiate auth — **HTTP/3 is not configured anywhere in this lab** (`grep -rn "http3" gitops/ infra/` — zero hits) |
| GHSA-w4v4-9rw7-5326 | CVE-2026-88008 | High (7.0) | `3.4.2`-`3.7.12` | `3.7.13` | a backend accepting `Upgrade: h2c` PLUS an unprotected router and a protected router pointing to the *same* backend service — **this lab's sole `IngressRoute` (`gitops/network/argocd-ingressroute.yaml`) has exactly one route per entrypoint, both matching the identical `Host(...) && PathPrefix(\`/\`)` with no auth middleware on either — no protected/unprotected split to bypass** |
| GHSA-f52w-8j3h-j724 | CVE-2026-88009 | High (8.8) | `3.0.0`-`3.7.12` | `3.7.13` | a catch-all `PathPrefix("/")` router reaching the same service as a stricter, path-guarded router — **same topology check as above: no second, path-guarded router exists for `argocd-server`** |
| GHSA-v67p-phpq-fc8x | CVE-2026-88004 | High (7.0) | `3.2.0`-`3.7.12` | `3.7.13` | `aliasHeadersStrategy`/`underscoreHeadersStrategy` in `delete`/`reject` mode, or default `forwardedHeaders` stripping, to spoof `X-Forwarded-*`/aliased headers past a downstream check — **no such Traefik header-strategy config exists anywhere in `gitops/` (`grep -rn "aliasHeadersStrategy\|underscoreHeadersStrategy\|forwardedHeaders"` — zero hits), and more importantly ArgoCD (the only backend behind Traefik) trusts no proxy header for authn/authz: `server.insecure=true` plain-HTTP with ArgoCD's own local/JWT session auth, no OIDC/Dex, no `X-Forwarded-*`/SSO-header trust anywhere in `gitops/argocd/`** — even a successful header-spoof has nothing to bypass here |
| GHSA-8fcf-v89g-xpg6 | CVE-2026-88010 | Moderate (6.3) | `3.6.11`-`3.7.12` | `3.7.13` | the `BasicAuth` middleware enabled and protecting a route — **`grep -rln "BasicAuth\|basicAuth\|basicauth" gitops/` — zero hits, no `BasicAuth` middleware exists anywhere in this lab** |

Every advisory's affected range includes `v3.7.8` — the version this lab
actually runs (bundled by the pinned k3s `v1.36.4+k3s1`, confirmed unchanged
via `github.com/k3s-io/k3s/releases`' own embedded-component-versions table,
same as the 2026-09-11 currency check already recorded). Each "requires"
column above was confirmed directly against this lab's real `gitops/`
manifests — `grep -rn` for `http3`, `BasicAuth`/`basicAuth`,
`aliasHeadersStrategy`/`underscoreHeadersStrategy`/`forwardedHeaders`, and a
direct read of the sole `IngressRoute` file's route/service topology and
ArgoCD's own auth config — not assumed (ADR-0004): **zero matches for every
single one.**

## Decision: no config change needed; version bump not yet possible

Every one of the 5 new advisories against the running Traefik version
requires a feature, middleware, or router topology this lab's `gitops/`
simply does not use — including the Critical HTTP/3 NTLM-reuse bug. No
HTTP/3 entry point, `BasicAuth` middleware, custom header-stripping
strategy, or multi-router-to-one-backend split exists anywhere in this
repo's manifests, and the one backend Traefik fronts (ArgoCD) trusts no
proxy header for authentication regardless.

A version bump isn't available yet regardless: no newer `k3s` release exists
in the `v1.36.x` line (`v1.36.4+k3s1` is still current) that would bundle a
fixed Traefik (`v3.7.13`); `v1.37.0` remains at `-rc5` (2026-09-10), no
stable cut. Same flip condition as the 2026-09-06 sweep: re-run this check
the next time [ADR-0030](../decisions/adr-0030-pin-k3s-version-explicitly.md)'s
pinned k3s version bumps (a k3s bump silently carries a new bundled Traefik
version with it) — **and, this cycle's own correction to that condition's
scope:** a full advisory re-sweep is also worth doing periodically even
*without* a k3s bump, since new GHSAs can be (and were, here) published
against an already-shipped Traefik version at any time — the 2026-09-11
entry's "no new GHSA... since the 2026-09-06 sweep" was an assumption, not a
live check, and this cycle found that assumption was already 8 days stale.

## What changed

`docs/dependency-register.md`: Traefik row updated with this sweep's result
and this writeup's link, same shape as the 2026-09-06 entry (ADR-0040 has no
dedicated "Re-evaluation log" section of its own to extend, so the result is
recorded in the register row directly, matching that established pattern).

No code/config change — comment/documentation only. `make ci` passes green.

## PR

(auto/traefik-ghsa-sweep-20260914) — autonomous scheduled executor run,
cycle 2 of this run, STEP 6b PLANNER-fallback filler.
