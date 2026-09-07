# Fix stale "shared Gateway HTTPS listener" terminology in CHARTER.md, README.md, docs/00-architecture.md, and docs/dependency-tree.md — post-ADR-0040 Traefik migration doc drift

**Core Value: "Docs don't drift".** ADR-0040 replaced Envoy Gateway with Traefik for
north-south ingress, and `gitops/platform/lab-gateway.yaml`'s own header comment
already documents the current shape correctly ("the shared lab TLS termination
(Traefik TLSStore, ADR-0040 — supersedes the GatewayClass/Gateway this used to hold
under Envoy Gateway/ADR-0008)"). `docs/dependency-tree.md` itself was inconsistent:
its front-door row (the `:8443` table entry) and its ArgoCD-apply-order wave-0 note
both already correctly described Traefik's `websecure` entrypoint terminated via the
shared `TLSStore`, but four other prose spots still described the current state using
pre-ADR-0040 Gateway-API language as if a literal `Gateway` resource with an
`https`/443 listener still exists:

- `CHARTER.md`'s "TLS certificate lifecycle" bullet (Target end-state section) —
  "the shared Gateway's HTTPS listener".
- `README.md`'s "TLS / certificates" row in the dependency/endpoints table — "the
  shared Gateway's `https`/443 listener".
- `docs/00-architecture.md`'s `cert-manager` row — "at the Gateway edge" / "the
  shared Gateway's HTTPS listener (:8443)".
- `docs/dependency-tree.md`'s ArgoCD apply-order table, wave 1 ("shared Gateway
  (after Gateway API CRDs)") and wave 6 ("the shared Gateway's HTTPS listener").

Fixed by rewording each spot to accurately describe the current mechanism —
Traefik's `websecure` entrypoint, TLS terminated via the shared `TLSStore`
(`gitops/network/traefik-tls-store.yaml`), backed by the wildcard
`*.127.0.0.1.nip.io` Certificate — matching the phrasing `docs/dependency-tree.md`
itself already used correctly elsewhere. The `lab-gateway` ArgoCD
Application/namespace itself was **not** renamed — that's a retained resource name,
not a literal Gateway API object (see `gitops/platform/lab-gateway.yaml`'s own
comment), and was out of scope here.

No manifest/code changes — pure doc correction. `make ci` (readme-check,
lab-ui-check) verified green; the one pre-existing local `not ok` in this
sandbox (`tests/forgejo-repo-secret.bats`'s `passes shellcheck` assertion,
because `shellcheck` isn't installed in this clusterless sandbox) is unrelated
to this diff (only `CHARTER.md`, `README.md`, `docs/00-architecture.md`, and
`docs/dependency-tree.md` changed) and is expected to pass in GitHub Actions'
`ci.yml`, which installs `shellcheck`.

Found via the executor's STEP 6b PLANNER fallback (this run's "Now / next" lane
was fully gated — see `plan/traefik-gateway-doc-drift-fix`, PR #1472, which added
this item) — a gap-analysis pass comparing CHARTER's Core Values against the repo's
actual docs, cross-checked against every real manifest via direct `grep`, not
assumed.

## PR

auto/traefik-gateway-doc-drift-fix
