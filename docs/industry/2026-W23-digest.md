# Industry digest — week 2026-W23

_Period: 2026-05-29 – 2026-06-06. Fetched and written 2026-06-06._

---

## At-a-glance

- **Vault v2.0.2** — breaking: `cap_ipc_lock` removed from container builds; operators must set `disable_mlock = true`. CVE-2026-39829 (RSA key-size cap) also patched.
- **Valkey 8.1.8 / 8.0.9** — HIGH-urgency: critical heap-use-after-free + three CVEs (CVE-2026-23479, CVE-2026-25243, CVE-2026-23631) across the 8.x branch.
- **Grafana Alloy v1.16.2** — critical CVEs in `x/crypto` and `x/net` patched; `pgx` bumped to 5.9.2.
- **Envoy Gateway v1.8.1** — auth bypass fixed in GatewayNamespaceMode; Envoy bumped to 1.38.1.
- **Longhorn v1.12.0** — V2 Data Engine reaches General Availability.

---

## Lab stack

### Vault v2.0.2 — 2026-06-05

Patch release in the v2 line. Two breaking changes: (1) the `cap_ipc_lock` Linux capability is no longer granted to the `vault` binary at build time, so containers relying on memory-locking must instead set `disable_mlock = true` in the Vault config and disable OS swap; (2) RSA keys are now capped at 8192 bits, fixing CVE-2026-39829. Go bumped to 1.26.4.

**What this means for the lab:** The lab's Vault pod must set `disable_mlock = true` (or confirm it already does) before upgrading to v2.0.2, otherwise the vault process will fail to start inside a container without `IPC_LOCK`. The ADR-0017 `restricted` Pod Security Standard also drops Linux capabilities by default, making this change aligned with that profile — but it is a silent breaking change on upgrade.

Source: <https://github.com/hashicorp/vault/releases/tag/v2.0.2>

---

### Valkey 8.1.8 / 8.0.9 / 9.1.0 — 2026-06-02

Three simultaneous releases. **8.0.9** (urgency: SECURITY) supersedes the revoked 8.0.8 and backports three CVE fixes: CVE-2026-23479 (use-after-free in unblock-client flow), CVE-2026-25243 (invalid memory access in RESTORE), CVE-2026-23631 (use-after-free during Lua/function execution with full sync). **8.1.8** (urgency: HIGH) additionally fixes a critical heap-use-after-free in `ACL LOAD` when client freeing is deferred, plus a ZDIFF memory leak and SENTINEL command injection hardening. **9.1.0** is the first stable 9.x release (new major line, urgency LOW).

**What this means for the lab:** The lab runs Valkey per ADR-0018. The 8.x CVE fixes are security-relevant and upgrading to 8.1.8 (or 8.0.9 from 8.0.x) is recommended. The new 9.1 line introduced and then reverted strict TLS validation as a breaking change (it was pulled back in 9.1.0-rc2), so the 8.x branch remains the safer upgrade path until 9.x stabilizes.

Source: <https://github.com/valkey-io/valkey/releases/tag/8.1.8> · <https://github.com/valkey-io/valkey/releases/tag/8.0.9>

---

### Grafana Alloy v1.16.2 — 2026-06-02

Patch release addressing critical security CVEs in Go transport libraries (`x/crypto`, `x/net`) and the `pgx` PostgreSQL driver (bumped to 5.9.2). Also fixes a potential deadlock in `loki.process` on config change and a stage mutation bug that caused unnecessary pipeline reloads. Go bumped to 1.26.3.

**What this means for the lab:** Alloy is the lab's primary telemetry collector (LGTMP stack). The `x/crypto`/`x/net` CVEs are in libraries used by many scrape and forward components; upgrading is advisable. No configuration changes required.

Source: <https://github.com/grafana/alloy/releases/tag/v1.16.2>

---

### Envoy Gateway v1.8.1 — 2026-06-05

Patch on the v1.8 line. Key fix: `fail-open` auth bypass in `GatewayNamespaceMode` (the mode used when the gateway and routes share a single namespace). Envoy proxy bumped to 1.38.1 (upstream security and stability patches). Also ships v1.7.4 in parallel (same fixes backported, Envoy 1.37.3, Go 1.25.11).

**What this means for the lab:** The lab uses Envoy Gateway as its sole north-south ingress per ADR-0008. If `GatewayNamespaceMode` is in use, the auth-bypass fix is security-relevant. The Envoy 1.38.1 bump also picks up upstream hardening.

Source: <https://github.com/envoyproxy/gateway/releases/tag/v1.8.1>

---

### ArgoCD v3.4.3 / v3.3.11 — 2026-05-28

Dual patch releases. CVE-2026-41240 fixed via a `dompurify` bump to v3.4.0 in the React UI. Additional fixes: CLI `app wait` returns correctly when the app is already in the desired state; git fetch depth settings now honoured; nil-pointer dereference in webhook mutations resolved.

**What this means for the lab:** The dompurify CVE is in the ArgoCD web UI; any user browsing the ArgoCD UI before upgrading is exposed to the XSS vector. Medium urgency.

Source: <https://github.com/argoproj/argo-cd/releases/tag/v3.4.3>

---

### External Secrets Operator v2.6.0 — 2026-06-05

Minor feature release. Adds a `provider_api_calls_count` Prometheus metric for the Keeper provider, Passbolt `v5-custom-fields` resource-type support, and OpenBao e2e test coverage. No breaking changes reported.

Source: <https://github.com/external-secrets/external-secrets/releases/tag/v2.6.0>

---

### Grafana v12.4.4 / v12.3.7 / v12.2.9 — 2026-06-04

Patch releases across three active minor lines. Detailed changelogs were not retrievable from the release page at fetch time; treated as routine patch releases.

Source: <https://github.com/grafana/grafana/releases/tag/v12.4.4>

---

### Grafana Mimir 3.1.0 — 2026-06-02

Major release (1440 PRs, 97 contributors). Notable additions: Kafka ingest now supports SCRAM, OAUTHBEARER, and AWS MSK IAM auth plus TLS/mTLS; rack-aware consumption and multi-broker seed config. Breaking changes: `-target=flusher` removed, TSDB v2 index mandatory for uploads, per-step stats removed when MQE is enabled, several deprecated flags purged.

Source: <https://github.com/grafana/mimir/releases/tag/mimir-3.1.0>

---

### Pyroscope v2.0.3 — 2026-06-03

Security-focused patch: dependency bumps and fixes per the release notes. Helm chart version synced with application version to ensure patched images deploy by default.

Source: <https://github.com/grafana/pyroscope/releases/tag/v2.0.3>

---

### k3d v5.9.0 — 2026-06-02

Feature release. Adds `--port-delete` flag, a `cluster restart` command, and registry port matching. Fixes Colima DNS resolution, Windows config path handling, and node drain/uncordon logic. Hardcoded k3s version reference updated from 1.21 to 1.32.

Source: <https://github.com/k3d-io/k3d/releases/tag/v5.9.0>

---

### Longhorn v1.12.0 — 2026-06-02

Major release. **V2 Data Engine is now Generally Available**, bringing IPv6/dual-stack support, topology-aware PV node affinity, configurable CSI storage capacity tracking, and default CPU allocation raised to 2 cores for better I/O separation. Notable constraint: V2 volumes require cluster-detach before patch upgrades; V2 Backing Images removed.

**What this means for the lab:** ADR-0013 landed Longhorn as an on-demand component. The V2 GA removes the experimental label; on-demand bring-up via `make longhorn-up` now has a production-grade storage engine available.

Source: <https://github.com/longhorn/longhorn/releases/tag/v1.12.0>

---

### Kiali v2.27.0 — 2026-06-02

New minor release. Release notes link to kiali.io; local-mode guidance updated. On-demand component per ADR-0012.

Source: <https://github.com/kiali/kiali/releases/tag/v2.27.0>

---

### Istio 1.30.1 / 1.29.4 / 1.28.8 — 2026-06-04

Coordinated patch releases across three active minor lines on the same day. Detailed changelogs were not retrievable at fetch time. On-demand component per ADR-0012.

Source: <https://github.com/istio/istio/releases/tag/1.30.1>

---

### Cilium 1.20.0-pre.3 — 2026-06-02

Pre-release. Notable additions: Gateway API `ExternalAuth` filter support for HTTPRoutes; Envoy proxy bumped to 1.37.x; GoBGP upgraded to v4.5.0; ~40 bug fixes; cilium-cni binary reduced ~80% in size.

Source: <https://github.com/cilium/cilium/releases/tag/1.20.0-pre.3>

---

## Ecosystem

- **Kubernetes**: No release in the window. Latest stable remains v1.36.1 (2026-05-12). Source: <https://github.com/kubernetes/kubernetes/releases>
- **Helm**: No release in the window. Latest is v4.2.0 (2026-05-14). Source: <https://github.com/helm/helm/releases>
- **RabbitMQ**: No release in the window. Latest is 4.3.1 (2026-05-20). Source: <https://github.com/rabbitmq/rabbitmq-server/releases>
- **KRO**: No release in the window. Latest is v0.9.2 (2026-05-08). Source: <https://github.com/awslabs/kro/releases>
- **moto**: No release in the window. Latest is 5.2.1 (2026-05-10). Source: <https://github.com/getmoto/moto/releases>
- **TiDB**: Nightly/patch snapshot builds only (v8.5.6-*) — no stable release. Source: <https://github.com/pingcap/tidb/releases>

---

## For the architect

- **ADR-0017** (Pod Security Standards `restricted`) may want a look because: Vault v2.0.2 removes `cap_ipc_lock` from its container binary — this aligns with `restricted` dropping Linux capabilities, but it is a silent breaking change that requires `disable_mlock = true` in the Vault configuration before upgrading.
- **ADR-0016** (default-deny NetworkPolicy) may want a look because: Valkey 8.x shipped multiple CVEs this week; upgrading the Valkey version used in the `data` namespace while its first default-deny overlay is in place is a good integration test of whether the new policies' egress rules allow the exporter traffic correctly.
- **ADR-0013** (Longhorn on-demand) may want a look because: Longhorn v1.12.0 promotes the V2 Data Engine to GA — the current ADR chose Longhorn partly for production-shaped storage semantics; the V2 GA changes the capability baseline.

---

## Fetch failures

| Project | Attempted URL | Error |
|---------|--------------|-------|
| Garage | `https://github.com/deuxfleurs/garage/releases.atom` | HTTP 404 — GitHub repo not found at this path |
| Garage (alt) | `https://git.deuxfleurs.fr/Deuxfleurs/garage/releases` | HTTP 403 |
| CNCF feed | `https://www.cncf.io/feed/` | HTTP 403 |
| Kubernetes blog | `https://kubernetes.io/feed.xml` | HTTP 403 |
| Istio release notes | `https://istio.io/news/releases/1.30.x/announcing-1.30.1/` | HTTP 403 |
| Grafana v12.4.4 release notes | GitHub releases page | Page load error (GitHub served partial HTML) |
| Mimir 3.1.0 release notes | `https://github.com/grafana/mimir/releases/tag/mimir-3.1.0` | HTTP 404 (tag format differs) |
| Artifactory | No public GitHub releases feed available | N/A |
