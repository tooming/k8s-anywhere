# Pin Vault's server image tag explicitly

(CHARTER **Core Values** §"Everything as code" + §"Recreate-from-code" + general
hardening; planner gap-analysis finding, 2026-07-24 — no prerequisites, no ADR
change needed, same reasoning as the Grafana image-tag override item: no ADR
governs Vault as a technology/version choice, only the delivery mechanism.)
Verified directly against the repo (not assumed, per ADR-0004):
`gitops/platform/vault.yaml` pins the `vault` chart at `targetRevision: 0.34.0`
but never sets an explicit `server.image.tag` — unlike every other
version-sensitive component in this repo (Grafana, Argo Rollouts, Valkey, Envoy
Gateway, Kiali, k3s/ADR-0030), the actual Vault **binary** version running in
this lab was only ever recorded in a prose comment ("chart v0.34.0 defaults to
a Vault 2.0.3 image"), not a field a `bats` test or a future architect
ADR-audit sweep could check mechanically. Same class of gap RFC #558
(ADR-0030) closed for k3s.

Verified live upstream (not training-data recall, ADR-0004): fetched
`raw.githubusercontent.com/hashicorp/vault-helm/v0.34.0/values.yaml` directly —
confirms the chart's actual default is `server.image: {repository:
hashicorp/vault, tag: "2.0.3"}` (the `injector`/`agentImage` defaults are
irrelevant since this Application sets `injector.enabled: false`). Cross-checked
`2.0.3` against every Vault CVE/security bulletin disclosed in 2026 findable
from this sandbox. Fetched Vault's own `CHANGELOG.md` directly
(`raw.githubusercontent.com/hashicorp/vault/main/CHANGELOG.md`) and confirmed,
by version section, three of the five: the `## 2.0.0` section fixes
`CVE-2026-5807` (unauthenticated root-token/rekey DoS — "sys/rekey endpoints
are now authenticated by default"), `CVE-2026-5052` (ACME SSRF — "Reject
obviously unsafe validation targets during ACME HTTP-01 and TLS-ALPN-01
challenge verification"), and `HCSEC-2026-07` (token exposure to auth plugins —
"Correctly remove any Vault tokens from the Authorization header when this
header is forwarded to plugin backends"). Two further bulletins —
`CVE-2026-3605` (KVv2 glob-wildcard delete DoS) and `HCSEC-2026-16` (audit
device directory-guard bypass) — are reported fixed by `2.0.0`/`2.0.1`
respectively by secondary sources (SentinelOne, GitLab Advisory DB; the
HashiCorp `discuss.hashicorp.com` bulletin pages themselves returned proxy/auth
errors to direct fetch from this sandbox) but were not independently
confirmed in the plain-text CHANGELOG.md — flagged explicitly rather than
asserted as verified, per ADR-0004. `2.0.3` (this pin) postdates all five
fixed versions either way. This is a pin-what's-already-running change, not a
version bump — the running Vault image does not change.

Added `image: {repository: "hashicorp/vault", tag: "2.0.3"}` under the
existing `server:` block in `gitops/platform/vault.yaml`'s `valuesObject`,
matching the chart's own default exactly (no-op for the running cluster).
Added a dated `Re-evaluation log`-style comment block above the `server:` key
recording this pin, the CVE-audit trail above, and a flip condition for the
next audit ("revisit when a bulletin names a version above `2.0.3` as
affected, or when bumping the chart `targetRevision` past `0.34.0`"). Extended
`tests/securitycontext-vault.bats` with two new assertions: `server.image.tag`
== `2.0.3`, `server.image.repository` == `hashicorp/vault` — a recurrence
guard mirroring this repo's other per-component image-tag pin assertions
(Grafana, Argo Rollouts, Valkey). No topology change and the running image is
identical to today's chart-default, so no README/`docs/dependency-tree.md`
update was made.

**ADR-0004 caveat:** this remote clusterless session cannot verify Vault
starts cleanly post-pin on a live cluster — the pin exactly matches what the
chart already deploys by default, so no behavior change is expected. Rollback
path: remove the `image:` block; ArgoCD self-heals back to the chart's own
default (currently identical); Vault is a single-replica StatefulSet with
persistent file storage, so a revert doesn't touch data.

`make ci` passed.

## PR

[#699](https://github.com/tooming/k8s-anywhere/pull/699)
