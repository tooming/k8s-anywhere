# ADR-0008 — Envoy Gateway for north-south ingress

- [x] **ADR-0008 — Envoy Gateway for north-south ingress** — Added `docs/decisions/adr-0008-envoy-gateway-not-traefik.md` documenting the choice of Envoy Gateway (Gateway API: HTTPRoute) over the k3s-default Traefik and Kubernetes `Ingress`; covers the shared-gateway pattern (`allowedRoutes: All`), the `*.127.0.0.1.nip.io` hostname strategy, and the rationale for using the same Envoy data plane as the planned Istio ambient mesh. Linked from `docs/decisions/README.md`. (PR #32)
