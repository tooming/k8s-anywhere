# Incident log — severity scheme & real incident history

A documented incident classification (severity) scheme, plus a running log of real
incidents this lab has actually hit — filed to close the one *structural* (not just
cadence) gap [`docs/dora-audit-readiness.md`](dora-audit-readiness.md) names for
Pillar 2 (Q6/Q8): no severity tiering existed anywhere in the repo, and no dedicated
artifact captured "what broke, in production-shape terms, and why" distinct from the
fix commit itself. Every entry below is a real, already-observed incident — cited
against the issue comment, PR, or session where it was actually found and (where
applicable) fixed — never a fabricated or illustrative example
([ADR-0004](decisions/adr-0004-no-fabricated-content.md)).

**Scope note.** This lab is a solo-operator, clusterless-by-default learning platform
(see [ROADMAP.md](../ROADMAP.md) rule #2) — not a continuously operated production
system. **No paging and no escalation path is an intentional non-goal here, not a
silent absence** (mirrors the gap `docs/dora-audit-readiness.md`'s Q7 already names
explicitly): there is no on-call rotation to page and no second responder to escalate
to. What this scheme *does* provide is a consistent way to classify blast radius when
an incident is found, and an honest, cumulative record of root causes — the two things
Q6 and Q8 flag as missing.

## Severity scheme

| Severity | Definition | Expected response (solo operator) |
|---|---|---|
| **P0** | Whole-lab-down, or a data-loss risk (a stateful namespace's backup/restore path is broken, a destructive `make` target misbehaves). | Fix in the same session it's found — nothing else takes priority. |
| **P1** | A single always-on component is down or degraded, or a security-relevant gap (an admission policy not enforcing, a NetworkPolicy hole, an exposed credential). | Fix in the same session, or the very next one if mid-investigation. |
| **P2** | An on-demand/heavy component (Harbor, TiDB, Istio, Longhorn, Kargo's pipeline) is broken, or a non-blocking functional defect in an always-on component. | Track as a ROADMAP/backlog item; fix on the next relevant executor pass. |
| **P3** | Cosmetic, documentation drift, or a low-value inefficiency with no functional impact. | Filler-lane item — cheap to defer indefinitely. |

## How to log a new incident

Copy this row shape (mirrors the `| Field | Content |` template already used in
[`docs/dora-audit-readiness.md`](dora-audit-readiness.md)'s "Template for a new
question"):

| Field | Content |
|---|---|
| Date | *when it was found (not necessarily when it started)* |
| Severity | *P0–P3, per the scheme above* |
| Component(s) | *namespace / ArgoCD Application / script affected* |
| Detection | *how it was found — `make status`, a live-cluster investigation, a CI failure, a maintainer report* |
| Root cause | *the actual mechanism, not just the symptom* |
| Fix | *PR number, or "fixed live" if it was a non-GitOps-managed change (Vault data, CI variables)* |
| Time to resolve | *wall-clock from detection to fix landing, or "unresolved" if still open* |
| Follow-up | *any recurrence guard added, or "none needed"* |

## Real incident history

| Date | Severity | Component(s) | Detection | Root cause | Fix | Time to resolve | Follow-up |
|---|---|---|---|---|---|---|---|
| 2026-07-29 | P0 | Cilium (cluster-wide — apiserver connectivity) | Live-cluster investigation while working issue [#631](https://github.com/tooming/k8s-anywhere/issues/631) | Cilium agents lost apiserver connectivity after a k3d node IP reshuffle. | Fixed live via `make cilium-up` (no PR — a runtime re-bootstrap, not a GitOps change). | Same session | None needed — a k3d node IP reshuffle is an environmental event, not a repo defect. |
| 2026-07-29 | P1 | `artifactory` namespace NetworkPolicy | Bringing Artifactory up to test issue [#631](https://github.com/tooming/k8s-anywhere/issues/631) | The `artifactory` namespace's default-deny NetworkPolicy had no intra-namespace allow, so `artifactory-oss` could never reach its own bundled `postgresql` — the `wait-for-db` init container hung forever and the pod never started. This means Artifactory had likely never actually come up successfully in this lab before this was found. | PR #884 (`allow-artifactory-intra-namespace.yaml`, mirroring the existing `harbor` carve-out in ADR-0016). | Same session | Verified live: `artifactory-oss` reached `6/6 Running` after the fix. |
| 2026-08-04 | P1 | `envoy-gateway-system` egress NetworkPolicy / Harbor | Live-cluster investigation while working issues [#631](https://github.com/tooming/k8s-anywhere/issues/631)/[#633](https://github.com/tooming/k8s-anywhere/issues/633) | `allow-envoy-proxy-backend-egress` allowlists specific backend namespaces by name, and `harbor` was never added when its route landed — every request to Harbor's HTTPRoute timed out (`downstream_remote_disconnect`) because the default-deny floor silently dropped the proxy's egress to it. | PR #968. | Same session | Verified live after merging: `curl http://harbor.127.0.0.1.nip.io:8080/api/v2.0/systeminfo` returned 200. |
| 2026-08-04 | P1 | Harbor admin credential (Vault + GitLab CI variables) | Live-cluster investigation while working issue [#631](https://github.com/tooming/k8s-anywhere/issues/631) | `secret/harbor/registry` in Vault held a password from `scripts/vault-bootstrap.sh`'s random-generation fallback that was never actually Harbor's real admin password, so the CI job's `docker login` could never have succeeded. | Fixed live — Vault's `secret/harbor/registry` and the GitLab `HARBOR_USER`/`HARBOR_PASSWORD` CI variables were updated to match Harbor's real current admin credential (`harbor-admin-creds` secret). Not GitOps-managed, no PR. | Same session | None yet — this data isn't declaratively managed, so there's no mechanical guard against it drifting again; a future ROADMAP item could add a CI check that exercises `docker login` against Harbor on a schedule. |
| 2026-08-04 | P2 | GitLab CI (no runner ever registered) | Triggering a pipeline via the API while working issues [#631](https://github.com/tooming/k8s-anywhere/issues/631)/[#633](https://github.com/tooming/k8s-anywhere/issues/633) — it sat in `pending` forever, `GET /runners` returned `[]` | No GitLab Runner has ever been registered against this lab's GitLab instance, so `.gitlab-ci.yml` has never actually executed a pipeline in this lab's history — not just a symptom of the two fixes above, but the reason neither issue #631's signed-image confirmation nor #633's Kargo-promotion confirmation could ever have succeeded, regardless of the registry/network state. | **Unresolved** as of this entry — runner setup (`gitlab/docker-compose.yml`, docker executor, privileged `docker:29-dind` service) was in progress per the latest #631/#633 comments. | Unresolved | Tracked by the standing `[Action required]` issues #631/#633 — this log entry will be updated with the fix once a runner is live and a real pipeline run completes. |

## See also

- [`docs/DR.md`](DR.md#recovery-cookbook-single-component) — per-symptom recovery
  steps; this log adds severity + root-cause context on top of those fixes.
- [`docs/dora-audit-readiness.md`](dora-audit-readiness.md) — Q6/Q8 (Pillar 2) cite
  this file as their evidence.
- [`docs/dora-resilience-mapping.md`](dora-resilience-mapping.md) — Pillar 2 section.
