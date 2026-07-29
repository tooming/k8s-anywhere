# ADR-0018 audit: Redis's AGPLv3 tri-license option kept, Valkey stays the choice

CHARTER **Core Values** §"Decisions written down, rejected options off-limits" +
§"Every dependency runs on a free / open-source tier" (ADR-0025). Architect-role
fallback (`executor.prompt.md` STEP 6b, planner→architect chain — "Now / next"
remains fully gated on standing maintainer-confirmation issues #631/#632/#633;
re-checked this cycle, still zero comments on any of the three).

## What was checked

This cycle ran a live upstream-release/CVE audit — not another text/pin-drift
diff (today's earlier sweeps already covered that ground exhaustively) but a
direct check of each ADR'd component's actual release notes and CVE
disclosures, per the architect routine's STEP 1/STEP 2b:

- **Vault** `2.0.3` (pinned) — already the current stable release; includes
  auth/ACL security fixes.
- **Envoy Gateway** `v1.8.3` (pinned) — already the latest release, including
  its TLS-secret-mismatch validation fix.
- **Istio** `1.30.3` (pinned, on-demand) — already the release that fixed
  ISTIO-SECURITY-2026-004's CVE batch across the 1.28–1.30 lines.
- **Kyverno** chart `3.8.2` (pinned) — verified via
  `raw.githubusercontent.com/kyverno/kyverno/v1.18.2/charts/kyverno/Chart.yaml`
  to map to appVersion `v1.18.2`, the release that fixed CVE-2026-4789 and
  CVE-2026-41323.
- **Argo Rollouts** chart `2.41.1` (pinned) — confirmed to map to appVersion
  `v1.9.1`, the release that fixed CVE-2026-35469.
- **Valkey** `8.0.10-alpine` (pinned) — already this ADR's own 2026-07-22
  security bump; no newer CVE-fixing tag exists on the `8.0.x` line.
- **RabbitMQ** `4.3.4-management` (pinned) — already the latest release.
- **Grafana** `13.0.3` (pinned) — directly checked against CVE-2026-27876
  (a critical, CVSS 9.1 RCE): confirmed via the CVE's real affected-version
  range that `13.0.0`+ was never vulnerable, so no gap exists.
- **Longhorn**, **TiDB**, **k3s**, **ArgoCD**, **Cilium**, **Garage**,
  **Trivy**/**Trivy Operator**, **Velero** — checked; nothing landed inside
  the last 14 days that changes any pinned version's safety (Longhorn was
  already re-checked yesterday, `docs/done/2026-07-28-adr-0013-longhorn-currency-recheck.md`;
  Cilium's only recent change is an unreleased `1.20.0-rc.1` pre-release;
  Velero's CNCF Sandbox org-transfer is in-progress and cosmetic; TiDB's
  apparent versioning-scheme change is on-demand and non-security).

Every currently-pinned version in this repo turned out to already be the
CVE-patched/current release — a genuinely different, and reassuring, result
from a sweep style this repo hadn't run before (prior sweeps diffed pin text
against a chart index/registry; this one checked live CVE/security-advisory
status directly, per ADR-0004 — no version claim above was inferred from
training knowledge without a live source).

## The one real finding — audit #829

The rejected-alternative side of the sweep (STEP 2b: "has the *rejected*
technology done something that would un-reject it?") surfaced one real trigger:
**Redis** (rejected by ADR-0010, superseded by ADR-0018's choice of Valkey) now
ships Redis 8.0+ under a tri-license that includes AGPLv3, an OSI-approved
license, alongside its original SSPLv1/RSALv2 terms.

**Decision: Keep.** AGPLv3 is still strong-copyleft, not the permissive
BSD-3-Clause Valkey ships (matching the rest of the lab's permissively-licensed
stack). ADR-0018's other two rationales — Linux Foundation vendor-neutral
governance and the cloud-provider-default shift to Valkey — are untouched.
Recorded as a dated Re-evaluation log entry in
`docs/decisions/adr-0018-valkey-not-redis.md` with its own flip condition, per
the architect routine's "Keep" resolution path — audit #829 opened and closed
in this same cycle (no audit outlives one cycle, per STEP 2).

## What changed

- `docs/decisions/adr-0018-valkey-not-redis.md` — new dated `### 2026-07-29`
  Re-evaluation log entry.
- No code/manifest change — every pinned version audited was already current
  or already safe; nothing to bump.

`make ci` passes (full local run, including bats/kustomize/kubeconform/terraform
— all now installed in this sandbox — plus lint). Closes #829.

## PR

(this run's `arch/adr-0018-redis-license-recheck` branch)
