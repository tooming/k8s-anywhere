- [ ] 🟡 **Traefik basicAuth Middleware for the Argo Rollouts dashboard**
  (RFC #1479 — architect decision 2026-09-07, closing audit #1478). Closes a
  Critical, unpatched, unauthenticated-mutation CVE (GHSA-366v-5xmx-36vh /
  CVE-2026-82277) against the exact dashboard appVersion (`v1.10.0`) this lab
  runs and exposes at `rollouts.127.0.0.1.nip.io` with zero auth today. See
  RFC #1479 for the full concrete spec (ExternalSecret + Vault seed reusing
  Kargo's established bcrypt/htpasswd pattern + Middleware + IngressRoute
  wiring + docs + bats coverage) — single-PR-sized, clusterless-deliverable,
  `make ci` is the only gate. (auto/argo-rollouts-dashboard-basicauth)
