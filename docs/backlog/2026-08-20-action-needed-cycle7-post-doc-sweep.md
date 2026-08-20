# [Action needed] Now/next still gated; post-doc-sweep clean (cycle 7)

**Date:** 2026-08-20
**Cycle:** 7th cycle this run

## What's blocked

Unchanged from every earlier cycle this run: the "Now / next" lane holds the
same three items — the two GitLab→Forgejo migration items (per their own
investigation notes: the rename needs a genuinely different auth mechanism,
SSH deploy keys vs. HTTPS+PAT, that needs live verification this remote
session can't perform) and the legacy capstone `Deployment` removal, gated
on issue #633. Re-checked both standing `[Action required]` issues (#633,
#1229) — no new comment on either since 2026-08-17/2026-08-18 respectively.

## What was tried this cycle

This run's earlier six cycles already landed real PRs (#1279 Mimir CVE bump,
#1280 retry_cmd dedupe, #1282 k3s ADR audit, #1283 Loki/Tempo date fix,
#1284 Kyverno Enforce doc fix, #1285 dashboard-count fix + recurrence guard)
— several found by spot-checking core docs (`docs/00-architecture.md`,
`docs/dependency-register.md`) for staleness against this run's own recent
findings. This cycle continued that angle and two fresh ones, all coming up
clean:

1. **Further docs/00-architecture.md / README.md / CHARTER.md spot-check** —
   grepped for any other embedded count/date/mode claim (dashboard counts,
   ArgoCD Application counts, Kyverno mode) beyond the ones already fixed
   this run. Found CHARTER.md's "~33 ArgoCD `Application`s" always-on-core
   count, but it's an explicitly approximate (`~`) claim with a documented,
   non-trivial counting methodology (issue #846's own recount excluded the
   4 "next wave" components and all heavy/on-demand ones from a much larger
   raw `kind: Application` count) that this session cannot safely reproduce
   without risking a wrong "fix" — left alone rather than guessing at a
   methodology.
2. **Trivy Operator chart-currency re-check** (named as an open "scope gap"
   in this week's industry digest — "no evidence of trivy-operator-specific
   drift, flagged as a scope gap rather than asserted stale"). Verified
   directly: `git ls-remote --tags aquasecurity/helm-charts` confirms
   `trivy-operator-0.35.0` is still the newest chart tag, matching the
   live pin exactly. ADR-0022's own Re-evaluation log already has a
   2026-08-07 entry confirming this same conclusion — re-verifying it
   independently found nothing new, so no ADR/digest edit made (would be a
   pure duplicate, against ADR-0004's spirit).
3. **Attempted to unblock ADR-0008's Envoy Gateway `v1.9.0` flip condition**
   (its own Re-evaluation log names the exact tooling gap: `helm template
   envoyproxy/gateway-helm --version v1.9.0` against this lab's real Gateway
   API CRDs). Tried installing `helm` via the official `get-helm-3` script
   and direct GitHub release-asset downloads — both blocked by this
   session's network egress policy (`get.helm.sh` and GitHub release-asset
   downloads both 403/404 through the proxy, confirmed via
   `$HTTPS_PROXY/__agentproxy/status`). Genuine environment limitation, not
   a permission boundary — left for a live-cluster or better-tooled session.

## Why this is the honest deliverable

Three real, verified checks (doc spot-check, Trivy Operator currency,
Envoy Gateway tooling attempt) all came back clean or genuinely blocked by
environment limits, not laziness. Recording honestly per ROADMAP rule #9 and
`executor.prompt.md` STEP 6b/STEP 8. The run continues — going straight back
to STEP 1 for the next cycle.
