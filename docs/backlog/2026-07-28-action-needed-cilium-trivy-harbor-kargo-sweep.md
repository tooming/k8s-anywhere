# [Action needed] Now/next still gated; Cilium/Trivy Operator/Harbor/Kargo CVE sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle via `gh`-equivalent MCP calls: all three still open, zero comments,
unchanged since 2026-07-21.

## What this run already shipped (earlier cycles, prior runs)

PR #758/#759, PR #762, PR #765, PR #766, PR #767, PR #768 (see those PRs'
bodies for detail — CVE audits across most of the always-on stack including
Grafana, RabbitMQ, Kyverno, cert-manager, KEDA, Argo Rollouts, External
Secrets, Garage, the full LGTMP stack, plus an UPGRADE-DRAFTER-lens sweep and
a JANITOR-lens cleanup check — all clean).

## This cycle's fresh angle

Swept four always-on/core components not covered by any of the prior
cycles' notes above: **Cilium** (ADR-0014), **Trivy Operator** (ADR-0022),
**Harbor** (ADR-0024, on-demand), and **Kargo** (ADR-0023). All four came
back clean, verified against real upstream sources (ADR-0004), not training
knowledge:

1. **Cilium** — pinned `1.17.18` (`gitops/platform/cilium.yaml`). Found
   **CVE-2026-33726** (Ingress NetworkPolicy bypass for pod→L7-Service
   traffic with a local backend, when Per-Endpoint Routing is enabled and
   BPF Host Routing is disabled), fixed in `1.17.14`/`1.18.8`/`1.19.2`. Our
   pin (`1.17.18`) is already past the `1.17.14` fix floor on the same minor
   line. Already patched.
2. **Trivy Operator** — pinned chart `0.34.0` (`gitops/platform/trivy-operator.yaml`,
   maps to operator `appVersion: 0.32.0`, confirmed via the chart's real
   `Chart.yaml`). No `trivy.image.tag` override in our `valuesObject`, so the
   embedded scanner defaults to the chart's own pinned tag — confirmed via
   the chart's real `values.yaml` at that release: `trivy.image.tag: 0.72.0`.
   The March 2026 Trivy supply-chain compromise (CVE-2026-33634) poisoned
   specifically `trivy` binary `v0.69.4` plus `trivy-action`/`setup-trivy`
   GitHub Action tags; this repo's `.gitlab-ci.yml` has no `trivy-action`
   reference at all (grepped, zero hits), and the operator's own scanner
   image (`0.72.0`) is a later release than the poisoned `v0.69.4`. Not
   affected either way.
3. **Harbor** (on-demand, ADR-0024) — pinned chart `1.19.1`
   (`gitops/platform/harbor.yaml`). Found **CVE-2026-4404** (CVSS 9.4,
   hardcoded default admin credentials `admin`/`Harbor12345`, affects Harbor
   `<=2.15.0`, fixed `2.15.1`+). Verified the actual chart/app mapping from
   `harbor-helm`'s real `Chart.yaml` at tag `v1.19.1` (not a search-engine
   summary, which initially disagreed with itself on this point — resolved
   by fetching the raw file directly per ADR-0004): `appVersion: 2.15.1` —
   already past the fixed floor. Independently, this repo's Harbor
   `valuesObject` was already configured with `existingSecretAdminPassword:
   harbor-admin-creds` (a Vault-issued random credential via ESO) rather than
   ever relying on the hardcoded default, so it would have been unaffected by
   the underlying weakness even on an older chart. Doubly clean.
4. **Kargo** — pinned chart `1.11.0` (`gitops/platform/kargo.yaml`). Found
   **CVE-2026-27111**/**CVE-2026-27112** (REST API promote-verb and batch
   resource-creation authorization bypasses, both fixed in `v1.9.3`) and
   **CVE-2026-24748** (unauthenticated `GetConfig()` access). Confirmed via
   `akuity/kargo`'s own release process that chart version tracks app version
   1:1 at release time — our pin (`1.11.0`) is two minor lines past the
   `1.9.3` fix floor. Already patched.

No genuine gap found in any of the four. No dedicated version-tracking ADR
exists for Trivy Operator or Kargo's CVE posture beyond ADR-0022/ADR-0023's
existing scope notes, so there is nowhere to record a Re-evaluation log entry
even where a check was worth doing — noted here for the record only, per the
same pattern as the LGTMP sweep note (2026-07-27).

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
