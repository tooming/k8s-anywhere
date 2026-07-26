# [Action needed] Now/next still gated; ArgoCD RCE lead already mitigated, second CVE batch clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (second cycle of 2026-07-26): all three still open, zero comments. No
new GitHub issues, no pending `docs/roadmap/incoming/` items.

## This cycle's fresh angle

Continuing the previous cycle's CVE-specific verification lens (see
[`2026-07-26-action-needed-cve-sweep-clean.md`](2026-07-26-action-needed-cve-sweep-clean.md)),
this cycle swept a second batch of pinned components not covered by the first
batch: ArgoCD itself, Velero, Trivy Operator, Istio, KEDA, Longhorn.

**Most promising lead, investigated in depth: an unauthenticated RCE in Argo
CD's `repo-server`** (unauthenticated internal gRPC `GenerateManifest` service,
abusable via Kustomize's Helm integration for command execution — no CVE
assigned, no upstream fix, publicly disclosed by security researchers in
July 2026 after an ~18-month unresolved private report). This looked like a
serious, real gap worth building a NetworkPolicy-tightening PR for. Before
writing one, checked `docs/decisions/adr-0016-default-deny-networkpolicy.md`'s
own Re-evaluation log first (per CLAUDE.md ADR-consultation discipline) —
**this exact disclosure was already audited on 2026-07-18 (audit #526,
predating this cycle by a week) and the decision already on record is "keep
the current posture — already mitigated."** That audit verified directly
against this lab's actual `gitops/argocd/networkpolicy/` overlay: `repo-server`
(:8081) and the bundled Redis (:6379) have no cross-namespace ingress rule
reachable from outside the `argocd` namespace (confirmed by checking every
other namespace's overlay for an egress rule targeting those ports — only two
exist, both scoped to TCP 80 only). The only residual exposure is
intra-namespace (any already-running pod inside `argocd` could reach
`repo-server`), which is the same accepted, documented trust-boundary
carve-out every tightly-coupled multi-component namespace in this lab uses
(ADR-0016's Carve-outs table), with its own explicit flip condition ("Argo CD
ships an official patch/CVE with a different recommended mitigation, or a
future item adds a new pod to `argocd` or a new cross-namespace egress rule
targeting 8081/6379"). Neither condition has occurred. **Building a
NetworkPolicy-tightening PR here would have re-litigated an already-decided
ADR audit finding — correctly did not build one.** Also checked: our `argo-cd`
chart pin (`9.7.1` → ArgoCD v3.4.4, per `infra/modules/argocd/variables.tf`)
predates neither of the two other 2026 ArgoCD ServerSideDiff secret-disclosure
CVEs found in the same search (CVE-2026-42880/CVE-2026-43824, GHSA-3v3m-wc6v-x4x3)
— confirmed directly against the advisory: affected range is `3.2.0-3.3.8`
only, patched in `3.2.11`/`3.3.9`; our `3.4.4` postdates the entire affected
range. (Separately, `global.image.tag: latest` in
`infra/modules/argocd/values.yaml` means the actual running image floats on
upstream `master`, newer still than the pinned chart's `3.4.4` baseline — an
already-documented, already-excepted deviation in
`gitops/kyverno/policies/disallow-latest-tag.yaml`, not a new finding.)

**Remaining components checked, all clean:**

| Component | Pinned version | CVE checked | Verdict |
|---|---|---|---|
| Velero | chart `12.1.0` | searched for a 2026 Velero-specific CVE; only found is CVE-2026-25679, which is Red Hat's OADP downstream product, not upstream `vmware-tanzu/velero` | not applicable |
| Trivy Operator | chart `0.34.0` | CVE-2026-33634 (trivy ecosystem supply-chain compromise, March 2026, affecting `trivy-action`/`setup-trivy` GitHub Actions and a malicious `v0.69.4-6` binary release) | not applicable — this repo's CI does not use `aquasecurity/trivy-action` or `setup-trivy` anywhere (`grep` across `.github/workflows/` and `.gitlab-ci.yml` returns no hits), and Trivy Operator's in-cluster scanner image is unrelated to the compromised release artifacts |
| Istio | chart `1.30.3` (on-demand, ADR-0012) | CVE-2026-31837 (JWKS fallback RSA-key leak/JWT forgery, CVSS 8.7, fixed 1.29.1/1.28.5/1.27.8 **and shipped-in 1.30.0**), CVE-2026-31838 (debug endpoint cross-namespace leak), CVE-2026-47774 (HTTP/2 HPACK memory exhaustion) | current — `1.30.3` postdates `1.30.0`, which already carries the fix per Istio's own 1.30 release notes |
| KEDA | chart `2.20.1` (appVersion confirmed `v2.20.1` via the chart's own GitHub release notes) | CVE-2026-53572 (PostgreSQL scaler connection-string injection, fixed 2.20.0) | current |
| Longhorn | chart `1.11.3` (on-demand, ADR-0013) | no specific 2026 Longhorn CVE surfaced in this search (only Longhorn's general CVE-resolution policy page) | no finding either way — not a confirmed gap |

No actionable version gap or unmitigated exposure found.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition (including a change to the
ArgoCD repo-server RCE flip condition in ADR-0016's audit #526); (c) a new
GitHub issue of any size.

This note is this cycle's honest record — a second, distinct CVE-research
pass (not a repeat of the first batch), including a real dead-end investigated
to its actual resolution rather than assumed — not a stopping point. The run
continues to the next cycle per `executor.prompt.md` STEP 8.
