# Traefik full GHSA sweep — bundled `v3.7.8` audited, 9 advisories checked, none exploitable in this lab's config

Extending this run's established "full advisory listing, not just currency" technique
(Envoy Gateway, Cilium, ArgoCD, KEDA+Velero, cert-manager) to Traefik — this lab's
current ingress layer since ADR-0040 replaced Envoy Gateway. Traefik had never had this
sweep done: it superseded Envoy Gateway (which was swept) after that sweep already
happened, so it was the one remaining always-on ingress component with no dedicated
security audit on record.

## A different shape than the prior sweeps

Every prior GHSA sweep in this run covered a component this repo pins directly (a
`targetRevision` in `gitops/platform/*.yaml`). Traefik is not one of those: it ships
bundled with k3s (ADR-0040 §"What does not change"; `gitops/platform/traefik-config.yaml`
only delivers a `HelmChartConfig` for probe/resource tuning, no chart `Application` of
its own to pin). Its actual version is whatever the pinned k3s release (`v1.36.4+k3s1`,
ADR-0030) bundles — confirmed directly via `k3s-io/k3s`'s `v1.36.4+k3s1` release notes'
"Embedded Component Versions" table: **Traefik `v3.7.8`**.

## What was found

All 9 published `traefik/traefik` GitHub security advisories near this version line were
checked directly (not assumed, ADR-0004):

| Advisory | Severity | Affected (tops out at) | Fixed | Requires (in this lab) |
|---|---|---|---|---|
| GHSA-5w68-77r2-r64c | **Critical** | `3.0.0`-`3.7.10` | `3.7.11` | `digestAuth` middleware — **not used anywhere** |
| GHSA-m6wx-622r-48r9 | High | `3.7.1`-`3.7.10` | `3.7.11` | `crossProviderNamespaces` restriction + multi-provider setup — **not used** |
| GHSA-g55h-rg46-x9c5 | High | `3.0.0`-`3.7.10` | `3.7.11` | a `TLSOption`/mTLS (`RequireAndVerifyClientCert`) conflict across a multi-host router — **no `TLSOption` resource exists anywhere in this lab** |
| GHSA-j994-9gqj-9hwq | High | `3.7.0`-`3.7.10` | `3.7.11` | plain `Ingress` objects with `nginx.ingress.kubernetes.io/auth-tls-*` annotations sharing an mTLS host — **this lab has zero plain `Ingress` objects** (IngressRoute CRD only) |
| GHSA-fgjj-px3w-67xx | High | `3.7.0`-`3.7.9` | `3.7.10` | the Kubernetes **Gateway API** provider (`HTTPRoute`/`GRPCRoute`/etc.) — **this lab uses Traefik's own `IngressRoute` CRD exclusively, zero Gateway API objects exist** |
| GHSA-62fc-8686-hfmq | Moderate | `3.7.0`-`3.7.9` | `3.7.10` | namespace-scoped RBAC in an attacker-controlled namespace (bypasses `allowCrossNamespace=false`, the default) — **single-operator lab, no untrusted multi-tenant RBAC principal exists** |
| GHSA-6765-c87h-8mrf | Low | `3.7.0`-`3.7.9` | `3.7.10` | `basicAuth` middleware with `headerField` set — **no `basicAuth` middleware used anywhere** |
| GHSA-7ghq-v6jf-g56c | Moderate | `3.0.0`-`3.7.11` | `3.7.12` | HTTP/3 (`http3: {}`) entry points — **HTTP/3 is not configured anywhere in this lab** |
| GHSA-cjr6-pf59-jq29 | High | `3.7.0`-`3.7.11` | `3.7.12` | Traefik's `kubernetesIngressNGINX` compat provider (plain `Ingress` + `nginx.ingress.kubernetes.io/*` annotations) — **this lab has zero plain `Ingress` objects and zero nginx annotations** |

Every advisory's affected range includes `v3.7.8` — the version this lab actually runs.
Confirmed each "requires" column directly against this lab's real `gitops/` manifests
(`grep -rl` for each vulnerable pattern — `digestauth`/`basicauth`/`forwardauth`
middlewares, `kind: HTTPRoute`/`GRPCRoute`/`TCPRoute`/`TLSRoute`/`Gateway`, `kind:
TLSOption`/`clientAuth`/`RequireAndVerifyClientCert`, `http3`/`quic`, plain `kind:
Ingress`/`nginx.ingress.kubernetes.io`): **zero matches for every single one.**

## Decision: no config change needed; version bump not yet possible

Every published advisory against the running Traefik version requires a feature or
configuration this lab's `gitops/` simply does not use — including the Critical
`digestAuth` bypass. No `TLSOption`, Gateway API object, plain `Ingress`, `basicAuth`/
`digestAuth` middleware, or HTTP/3 entry point exists anywhere in this repo's manifests.

A version bump isn't available yet regardless: no newer `k3s` release exists in the
`v1.36.x` line (`v1.36.4+k3s1` is current, confirmed via the `k3s-io/k3s` releases page)
that would bundle a fixed Traefik (`v3.7.11`/`v3.7.12`). **Flip condition** (mirroring
this run's other "hold, re-check on next release" entries): re-run this sweep the next
time `docs/decisions/adr-0030-pin-k3s-version-explicitly.md`'s pinned k3s version bumps,
since a k3s bump silently carries a new bundled Traefik version along with it — the
inverse of every other component's independent chart pin, where the check triggers on
*this* component's own version changing.

## What changed

`docs/dependency-register.md`: Traefik row updated with the sweep result and this
writeup's link (ADR-0040 has no dedicated "Re-evaluation log" section of its own to
extend — same shape as this run's ArgoCD sweep, which also recorded its result directly
in the register row rather than inventing one).

No code/config change — comment/documentation only. `make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1468
