# [Action needed] Now/next still gated; Vault ACL policy least-privilege audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#839](https://github.com/tooming/k8s-anywhere/pull/839) (full STEP 6b
chain walked explicitly, triager confirmed clean).

## This cycle's fresh angle

A security-scoping check no prior `docs/backlog/` note has run: whether
Vault's own ACL policies (`scripts/vault-bootstrap.sh`, the only place this
repo defines Vault policies — no separate `.hcl` policy files exist) are
least-privilege-scoped.

Found exactly **one** policy, `eso-read`, granting `read` on the wildcard
path `secret/data/*` — at first glance a broad, blanket grant worth
double-checking. Traced its actual blast radius before flagging it:

- Exactly **one** Kubernetes auth role exists (`auth/kubernetes/role/eso`),
  and it is bound **only** to the `external-secrets` ServiceAccount in the
  `external-secrets` namespace (`bound_service_account_names=
  external-secrets bound_service_account_namespaces=external-secrets`).
  No other ServiceAccount in the cluster can assume this Vault identity.
- This is the standard, accepted External Secrets Operator deployment
  pattern: ESO's own controller is the single trusted secret-broker for the
  whole cluster and legitimately needs broad backend read access to serve
  `ExternalSecret` requests originating from every namespace; the actual
  per-tenant access control is enforced on the Kubernetes side (RBAC on
  `ExternalSecret`/`SecretStore` objects, namespace scoping), not by a
  separate Vault ACL per consuming namespace. A single broad policy bound
  to a single, narrowly-scoped auth role is the correct shape for this
  pattern, not an over-privilege gap.

**Conclusion: no real gap.** The wildcard scope is intentional and
appropriately contained by the auth-role binding, not an oversight.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct security
check (Vault ACL least-privilege scoping) that correctly traced a
plausible-looking wildcard grant to its actual (narrow) blast radius before
concluding it's fine. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
