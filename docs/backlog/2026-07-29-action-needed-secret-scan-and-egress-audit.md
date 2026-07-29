# [Action needed] Now/next still gated; secret-scan + broad-egress NetworkPolicy audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#831](https://github.com/tooming/k8s-anywhere/pull/831), the prior
cycle's own `[Action needed]` PR (full-toolchain `make ci` verification +
fallback-chain re-check).

## This cycle's fresh angle

Re-running the same fallback-chain checks (planner/upgrade-drafter/doc-drift/
janitor) a second time in the same run within minutes would be pure
duplication — nothing external changes that fast. Per `executor.prompt.md`
STEP 8's "try a lens the last pass didn't" guidance, this cycle instead ran a
**security-focused sweep no prior `docs/backlog/` note has covered**
(checked via `grep -l "secret.scan\|hardcoded secret" docs/backlog/*.md
docs/done/*.md` — no hits):

1. **Hardcoded-secret grep sweep.** Searched every `.yaml`/`.yml`/`.tf`/
   `.tfvars`/`.sh` file under `gitops/`, `infra/`, `scripts/` for
   password/token/apiKey/private-key-looking literals (excluding known-safe
   `ExternalSecret`/`SecretStore`/`secretKeyRef` reference patterns). **Zero
   matches.**
2. **Raw `Secret` manifest check.** `grep -rlE "^kind:\s*Secret\s*$"` across
   `gitops/` — **zero matches**. Every credential in this repo genuinely
   flows through the ExternalSecrets Operator + Vault pattern (ADR-0002's
   architecture), not a literal manifest, confirmed directly rather than
   assumed.
3. **PEM/private-key block check.** `grep -rl "BEGIN.*PRIVATE KEY\|BEGIN RSA\|
   BEGIN OPENSSH"` repo-wide — **zero matches** outside nothing (no fixture
   dir even needed excluding).
4. **Provider major-version re-check** (verifying a fix from an earlier
   today's cycle actually landed, not re-doing the discovery): confirmed
   `infra/modules/argocd/main.tf`'s `hashicorp/helm` constraint is now
   `~> 3.0` and `infra/modules/oracle-k3s-cluster/main.tf`'s `oracle/oci`
   constraint is now `~> 8.0` — both already bumped past the major-line gap
   `docs/backlog/2026-07-28-action-needed-terraform-provider-major-line-sweep.md`
   (issue #791) flagged; that issue no longer appears in the open-issues list,
   confirming it was resolved this same day.
5. **Broad-egress NetworkPolicy audit.** Grepped every `NetworkPolicy` under
   `gitops/*/networkpolicy/` for `0.0.0.0/0` egress CIDRs (8 files) and
   read each one: every single one is `podSelector`-scoped to a specific
   component (not namespace-wide `{}` except Trivy's vuln-DB pull, which is
   itself scoped to TCP 443 only) and port-scoped to exactly the port(s) that
   component's documented external dependency needs (GitHub release CDN,
   ghcr.io vuln-DB, kubelet/cAdvisor and Cilium agent metrics on
   `hostNetwork: true` pods where podIP==nodeIP, which structurally requires
   an `ipBlock` rather than a `namespaceSelector`). Each file's own header
   comment already documents the CIDR-vs-FQDN tradeoff (Cilium `toFQDNs` is
   noted as unreliable in this kube-proxy-free lab). No unscoped/broad rule
   found — this is deliberate, already-reasoned design, not a gap.

No bounded, real, behavior-preserving cleanup or upgrade qualified this cycle.
`make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct
security-focused check, not a repeat of the prior cycle's toolchain/CI-tooling
angle. The run continues to the next cycle per `executor.prompt.md` STEP 8;
this is not a stopping point.
