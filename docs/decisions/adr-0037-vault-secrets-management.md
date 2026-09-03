# ADR-0037 — HashiCorp Vault for secrets management

**Status.** Adopted (retroactive record). Architect decision, self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2 (no binding ADR contradicted — this
closes a documentation gap on an already-implemented, already-live component, not a new
technical choice). Always-on-core component.

---

## Context

The lab needs a real secrets backend — something that actually stores and serves
credentials, as opposed to External Secrets Operator (ADR-0036), which only *syncs*
secrets from a backend into native `Secret` objects but holds none itself. This has been
solved since early in the lab's history by deploying **HashiCorp Vault**
(`gitops/platform/vault.yaml`, sync-wave 1) as a single-node, file-storage-backed
server: every credential ESO delivers to another component (Garage RPC/S3 keys, Harbor
admin/registry/S3 creds, Grafana admin, Kargo admin, Velero S3, ACK AWS creds, the
capstone app key) is actually held in Vault's KV v2 engine, reached via ESO's
Kubernetes-auth `ClusterSecretStore` at `http://vault.vault.svc.cluster.local:8200`.
A companion `vault-unsealer` Deployment (`gitops/vault/unsealer.yaml`) auto-re-unseals
Vault after every pod restart using a Shamir key held in a Kubernetes `Secret`
(lab-only trade-off — a real deployment would use a proper auto-unseal mechanism, e.g.
a cloud KMS; this lab's threat model doesn't call for one).

**Why this ADR is only being written now.** Same root cause as ADR-0036's own gap:
Vault was never compared against an alternative at adoption time — it was the
infrastructure glue standing up the "real secrets backend" role every other ADR assumes
exists, the same way ESO was the glue for the sync mechanism. `docs/dependency-register.md`
explicitly scopes itself to "pure re-indexing of content that already exists in
`docs/decisions/`", and Vault had no ADR to index — so it never got a row, unlike every
peer always-on-core component. Unlike ESO, this gap left something worse than a missing
register row: **the actual version-history/security-audit trail lived inline as YAML
comments** in `gitops/platform/vault.yaml` (the only version-sensitive component in this
repo that did this — every other one already points at its own ADR's Re-evaluation log).
That's real, carefully-verified content (see below), just filed in the wrong place —
this ADR is where it belongs, and this cycle's own gap-analysis (a full security sweep of
this lab's remaining un-ADR'd always-on-core components) is what found it missing.

---

## Decision

Adopt **HashiCorp Vault** (open-source/BSL-licensed community edition, not Vault
Enterprise), the de-facto-standard secrets-management server, deployed via its
**official Helm chart**.

### Chart + version

- **Chart:** `vault` from `https://helm.releases.hashicorp.com`.
- **Current chart pin:** `0.34.1` (`gitops/platform/vault.yaml`).
- **Current server image pin:** `hashicorp/vault:2.1.0`, set explicitly rather than
  inherited from the chart default (2026-07-24, closing a real gap: "what version are
  we running" was previously only answerable from a prose comment, not a field a bats
  test or a future ADR-audit sweep could check — every other version-sensitive
  component in this repo already pinned explicitly). The `vault-unsealer` Deployment's
  own `hashicorp/vault:2.1.0` image (used only for its CLI, to run `vault operator
  unseal`) is bumped in lockstep with the server pin — both must agree, since the
  unsealer's CLI talks to the server's API.
- **Storage:** `standalone` mode, `storage "file"` on a 1Gi PVC (`dataStorage`) — a
  deliberate ADR-0005 single-host trade-off, not pretend-HA.
- **TLS disabled** (`global.tlsDisable: true`) — lab-only; a real deployment would
  terminate TLS at Vault itself or a sidecar.
- **Injector disabled** (`injector.enabled: false`) — this lab delivers secrets to
  workloads via ESO's `ExternalSecret` → native `Secret` path (ADR-0036), not Vault
  Agent's sidecar-injection model. Two delivery mechanisms would be redundant.
- **Namespace:** `vault`.

### Security posture (already implemented, verified directly)

- **PSA `restricted`**, no carve-out: `runAsNonRoot: true`, `runAsGroup: 1000`,
  `runAsUser: 100`, `fsGroup: 1000`, `seccompProfile.type: RuntimeDefault` at the pod
  level; `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`,
  `readOnlyRootFilesystem: true` at the container level (`statefulSet.securityContext`
  in `vault.yaml`'s `valuesObject`) — the chart's own `disable_mlock = true` config is
  the required counterpart, since `restricted` doesn't grant `cap_ipc_lock`. An explicit
  `tmp` `emptyDir` volume backs `/tmp` for the read-only root filesystem (the chart's
  `home` mount at `/home/vault` is already an unconditional emptyDir).
- **NetworkPolicy** (`gitops/vault/networkpolicy/`, ADR-0016 fan-out): scoped ingress/
  egress for the API port, the unsealer's access, and ESO's cross-namespace client
  traffic.
- **Footprint controls:** `resources.requests: {cpu: 50m, memory: 128Mi}` /
  `limits: {cpu: 500m, memory: 256Mi}`.
- **Telemetry exposed, unauthenticated:** `unauthenticated_metrics_access = true` in
  the listener's `telemetry` stanza — a deliberate lab trade-off (TLS is already
  disabled and the UI is already open cluster-internally; a real deployment would
  require a scrape token) enabling `GET /v1/sys/metrics?format=prometheus` without a
  token. Real metrics this exposes, verified directly against `hashicorp/vault`'s own
  source (`vault/core.go`, `vault/core_metrics.go`, `vault/expiration.go` — not docs
  prose, ADR-0004): `vault_core_unsealed`, `vault_core_active`,
  `vault_core_in_flight_requests`, `vault_expire_num_leases`.
- **Must be initialized + unsealed once after a fresh deploy** (`make` targets handle
  this; the `vault-unsealer` Deployment handles every unseal after that).

### Observability

Alloy scrapes Vault's own `/v1/sys/metrics` endpoint (the telemetry stanza above); a
Grafana dashboard panel row surfaces the real series named above (verified against
source, not docs, ADR-0004) — see `docs/dora-audit-readiness.md` Q7 for the
`VaultSealedDegraded`/pod-readiness alerting rules built on this same telemetry.

### Test coverage

`tests/securitycontext-vault.bats` (chart/image pin, PSA-restricted securityContext,
`vault-unsealer` image lockstep), plus NetworkPolicy and observability coverage in
their own per-scope bats files — all already exist and pass.

---

## Scope & exceptions

**In scope (already shipped, this ADR is a retroactive record, not new work):** the
server, `vault-unsealer`, namespace/PSA, NetworkPolicy fan-out, telemetry, and the
ESO `ClusterSecretStore` integration point listed under Context above.

**Out of scope:** evaluating alternative secrets backends (e.g. cloud-native secret
managers, SOPS+age, Kubernetes Secrets encrypted at rest alone) — no case has been made
to reconsider Vault, and doing so now would be re-litigating a working, unproblematic
choice rather than closing a real gap. Also out of scope: Vault Enterprise features
(this lab runs the open-source/BSL community edition only, per ADR-0025's free/OSS-tier
rule) and the auto-unseal-via-cloud-KMS pattern a production deployment would use
instead of this lab's Shamir-key-in-a-Secret shortcut.

---

## Re-evaluation log

ADR audits record their outcome here when the decision is kept or a version is
bumped. The four entries below predate this ADR's own existence — they're migrated
verbatim (content preserved, not re-verified retroactively) from
`gitops/platform/vault.yaml`'s own inline comments, the only place this history
previously lived, per this ADR's own Context section above.

### 2026-07-24 — pinned server image at `2.0.3` (the chart v0.34.0 default)

**Trigger.** ROADMAP item "Pin Vault's server image tag explicitly" — every other
version-sensitive component in this repo (Grafana, Argo Rollouts, Valkey, Envoy
Gateway, Kiali, k3s/ADR-0030) already pinned its running version explicitly; Vault
previously did not.

**Verified directly (not assumed, ADR-0004).** Cross-checked against every 2026
Vault CVE/security bulletin findable from this sandbox at the time. Confirmed
directly in Vault's own `CHANGELOG.md` (fetched live from
`raw.githubusercontent.com/hashicorp/vault/main/CHANGELOG.md`, not training-data
recall): the `2.0.0` section fixes CVE-2026-5807 (unauthenticated root-token/rekey
DoS — "sys/rekey endpoints are now authenticated by default"), CVE-2026-5052 (ACME
SSRF — "Reject obviously unsafe validation targets during ACME HTTP-01 and
TLS-ALPN-01 challenge verification"), and HCSEC-2026-07 (token exposure to auth
plugins — "Correctly remove any Vault tokens from the Authorization header when
this header is forwarded to plugin backends"). Two further bulletins found only via
secondary sources (SentinelOne, GitLab Advisory DB; HashiCorp's own
`discuss.hashicorp.com` bulletin pages returned proxy/auth errors to direct fetch
from this sandbox) — CVE-2026-3605 (KVv2 glob-wildcard delete DoS) and HCSEC-2026-16
(audit device directory-guard bypass) — are both reported fixed by `2.0.0`/`2.0.1`
respectively; not independently confirmed in the plain-text `CHANGELOG.md`, flagged
per ADR-0004 rather than asserted as verified. `2.0.3` (this pin) is newer than all
five fixed versions either way.

**Decision: pin `2.0.3`.**

**Flip condition.** Revisit when a bulletin names a version above `2.0.3` as
affected, or when bumping the chart `targetRevision` past `0.34.0` (a later chart
may change the default image tag).

### 2026-08-05 — bumped `2.0.3` → `2.0.4`

**Trigger.** HashiCorp's published `CHANGELOG.md` has no `2.0.x` section at either
tag (a gap in their own changelog publishing for this release line, not silently
worked around — confirmed via a real clone + `git log v2.0.3..v2.0.4` instead).

**Verified directly.** Three "security:"-titled commits in that range turn out to
be false-positive suppressions, not real vulnerabilities (their own origin commits
are titled "Suppress false positive for GO-2026-5856 & 4970" and the same shape for
GO-2026-5298) — these do NOT count toward the flip condition. Two fixes ARE real:
`go.mod`/`go.sum` bump `klauspost/compress` to `v1.18.7` and
`go.opentelemetry.io/otel` to `v1.44.0`, resolving GO-2026-5158 and GO-2026-5841
(real dependency CVEs). Separately, a "Fix Goroutine Leak in Seal Encryption" commit
touches `vault/seal/seal.go` — the shared encrypt/decrypt path every seal type
(including this lab's Shamir/file-storage seal) goes through, a real reliability
fix. Satisfies this pin's flip condition in spirit (a real security-relevant fix
past `2.0.3`) even though no public bulletin names `2.0.3` itself as affected.

**Decision: bump to `2.0.4`.**

**Flip condition.** Revisit when a bulletin names a version above `2.0.4` as
affected, or when bumping the chart `targetRevision` past `0.34.0`.

### 2026-08-19 — chart bumped `0.34.0` → `0.34.1`

**Trigger.** Upstream tagged `0.34.1` (2026-08-13, `hashicorp/vault-helm`).

**Verified directly.** A direct `values.yaml` diff between the two tags (fetched
both raw, not assumed) shows only default-image-tag bumps (`vault-k8s` 1.7.5→1.7.6,
`vault-csi-provider` 1.7.3→1.7.4, `server.image.tag`/injector image default
`2.0.3`→`2.0.4`) plus one bug fix (a license-secret-volume `defaultMode`
octal/decimal rendering fix for `python-yq` compatibility) — this lab already pins
`server.image.tag` explicitly (already `2.0.4`, unaffected by the chart default)
and doesn't use the injector, CSI provider, or a license secret, so the rendered
manifest for this Application is unaffected; this is a pure chart-currency bump,
not a behavior change.

**Decision: bump to `0.34.1`.**

**Flip condition.** Revisit the image pin when a bulletin names a version above
`2.0.4` as affected; revisit the chart pin when a newer `vault-helm` tag ships past
`0.34.1`.

### 2026-09-03 — ADR authored (retroactive record); server image bumped `2.0.4` → `2.1.0`

**Trigger.** This cycle's gap-analysis pass (a full security sweep of this lab's
remaining un-ADR'd always-on-core components, following the same technique already
applied to ESO/ADR-0036) found Vault itself had no dedicated ADR and no
`docs/dependency-register.md` row, despite being explicitly named in CHARTER's own
Goals section ("the secrets flow: Vault → External Secrets → workload"). While
authoring this record, re-checked currency: `v2.1.0` (GitHub releases,
2026-09-01) is one release past the `2.0.4` pin this ADR was about to document as
current.

**Verified directly (not assumed, ADR-0004).** `github.com/hashicorp/vault/security/
advisories` has zero published GitHub-native advisories for this repo — HashiCorp
publishes its own bulletins separately via `discuss.hashicorp.com`, which remained
egress-blocked from this sandbox (same limitation the 2026-07-24 entry above already
hit). `v2.1.0`'s own GitHub release notes (fetched directly, not the ambiguous
`main`-branch `CHANGELOG.md` view which resolved to an unrelated Enterprise-line
section on a first attempt — caught and corrected by cross-checking against the
real releases-list page instead) list, under a **Security** heading: `go.etcd.io/
etcd/client/pkg/v3` bumped to `v3.7.1` (fixes `GO-2026-6107`) and
`software.sslmate.com/src/go-pkcs12` bumped to `v0.7.2` (fixes `GO-2026-5052` — a Go
vulnerability-database ID, unrelated to the differently-formatted `CVE-2026-5052`
already fixed back in `2.0.0`, despite the coincidentally similar number). No
Breaking Changes or Deprecations section in the release notes; the release's
feature additions (Agentic IAM/Enterprise Agent Registry UI, PKI DNS-01/PKCS12/JKS
support, Transit SLH-DSA) are all Enterprise-only or PKI-engine features this lab
doesn't use — the OSS server binary this lab actually runs is unaffected beyond the
two dependency-security fixes above.

**Decision: bump to `2.1.0`.** `gitops/platform/vault.yaml`'s `server.image.tag`
and `gitops/vault/unsealer.yaml`'s image both bumped in lockstep (the unsealer's
image is only used for its `vault` CLI binary talking to the server's API, so the
two must agree). `tests/securitycontext-vault.bats` updated (both pin assertions +
new "no stray `2.0.4`" guards on each). The inline Re-evaluation log this ADR
migrates (above) is removed from `vault.yaml`'s comments, replaced with a short
pointer to this ADR — matching every other version-sensitive component in this
repo.

**ADR-0004 caveat.** This remote, clusterless session verified the release notes
and dependency-fix facts directly, but cannot verify Vault starts cleanly, unseals
correctly via the existing Shamir key, and ESO's `ClusterSecretStore` continues
resolving secrets against it post-bump on a live cluster. Rollback is a two-line
revert (`vault.yaml`'s `server.image.tag` + `unsealer.yaml`'s `image`); Vault's
`storage "file"` PVC data is untouched by an image-tag change either way.

**Flip condition (next re-evaluation).** Revisit when a bulletin names a version
above `2.1.0` as affected, when `discuss.hashicorp.com` becomes reachable from a
future session (closing the standing verification gap every entry above has hit),
or when bumping the chart `targetRevision` past `0.34.1`.

---

## Files this record touches

| Path | Role |
|------|------|
| `docs/decisions/adr-0037-vault-secrets-management.md` | This ADR |
| `docs/dependency-register.md` | New Vault row, indexing this ADR |
| `docs/decisions/README.md` | New index entry |
| `gitops/platform/vault.yaml` | Server image bumped `2.0.4`→`2.1.0`; inline history replaced with a pointer here |
| `gitops/vault/unsealer.yaml` | Image bumped in lockstep |
| `tests/securitycontext-vault.bats` | Pin assertions updated + new stale-tag guards |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Vault lands as an ArgoCD `Application`; no `helm install`. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Telemetry dashboard sources real `/v1/sys/metrics` scrape data only; this ADR's own claims were verified directly, not assumed. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-node `standalone` storage is a deliberate lab trade-off; a real deployment would use Vault's HA/Raft storage backend. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `vault` namespace carries its own default-deny + explicit-allow overlay. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | `restricted` PSA, zero carve-out — the `disable_mlock` config is the required counterpart. |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | Open-source/BSL Community Edition, no Enterprise license required. |
| [ADR-0036](adr-0036-external-secrets-vault-sync.md) | ESO is the sync mechanism reading from this ADR's server; the two ADRs' Context sections cross-reference each other for the full secrets-flow picture. |
