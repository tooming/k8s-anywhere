# [Action needed] Now/next still gated; Cilium/RabbitMQ/cert-manager/KEDA currency verified clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## This cycle's fresh angle

Today's prior cycles (2026-07-29) already exhausted chart-currency checks for
ack-s3, Velero, Argo Rollouts, Kyverno, Grafana, Longhorn, Istio, Kiali,
Kargo, Harbor, external-secrets, KSM/node-exporter, TiDB Operator, and
Trivy Operator (see the other `docs/backlog/2026-07-29-action-needed-*.md`
files). Four always-on/on-demand pins hadn't been directly re-verified by
any of those: **Cilium** (ADR-0014), **RabbitMQ** (ADR-0009),
**cert-manager** (ADR-0028), and **KEDA** (ADR-0029). Checked each directly
against its own upstream GitHub releases:

- **Cilium** — pinned `gitops/platform/cilium.yaml` `targetRevision:
  1.17.18`. ADR-0014's own Re-evaluation log already recorded a
  2026-07-28 audit (#772) of CVE-2026-33726, concluding the pin is past the
  `1.17.14` fix floor. Re-checked `cilium/cilium`'s release list directly
  today: `1.17.18` is still the newest tag on the `1.17.x` line (newer
  `1.18.x`/`1.19.x`/`1.20.0-rc.1` lines exist but are a deliberate
  major/minor jump this lab doesn't track per the existing "smallest safe
  delta" pattern). **No bump available on the pinned line.**
- **RabbitMQ** — pinned `gitops/data/rabbitmq/statefulset.yaml` `image:
  rabbitmq:4.3.4-management`. Checked `rabbitmq/rabbitmq-server`'s release
  list directly: `4.3.4` (2026-07-23) is the newest tag, newer than the
  `4.2.9` maintenance release on the older line. **Already current.**
- **cert-manager** — pinned `gitops/platform/cert-manager.yaml`
  `targetRevision: 1.21.0`. Checked `cert-manager/cert-manager`'s release
  list directly: `v1.21.0` is the latest stable tag (its own release notes
  cite a HIGH-severity RBAC advisory, GHSA-8rvj-mm4h-c258, already fixed in
  this exact version — not an open gap). **Already current.**
- **KEDA** — pinned `gitops/platform/keda.yaml` `targetRevision: 2.20.1`.
  Checked `kedacore/keda`'s release list directly: `v2.20.1` is the latest
  tag (older `v2.18.3`/`v2.17.3` patches back-ported a since-fixed CVE that
  doesn't apply to the current line). **Already current.**

**Conclusion: no gap.** All four are already at the newest available
version on their pinned line — no `upgrade/*` PR qualifies this cycle.
`make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — four component pins that no
earlier cycle today had directly re-verified, all confirmed current. The
run continues to the next cycle per `executor.prompt.md` STEP 8; this is
not a stopping point.
