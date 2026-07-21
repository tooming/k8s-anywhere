# Add missing `make tfstate-clean` target + ADR make-target drift guard

`docs/decisions/adr-0007-off-cluster-garage-tfstate-backend.md`'s `## Files`
section states: "torn down via `make tfstate-down` (stops the container; the
Docker volume `tfstate_data` persists until `make tfstate-clean`)" — but no
`tfstate-clean` target existed anywhere in the `Makefile`. Only `tfstate-up`
(bring the off-cluster Garage up + bootstrap it) and `tfstate-down` (stop the
container, explicitly documented as keeping its volume/state) existed. This
was a dangling capability reference: the ADR described real, binding
machinery ("the Docker volume ... persists until `make tfstate-clean`") that
did not exist to run — a stale-doc-reference class of drift (ADR-0004 risk),
not caught by any existing mechanical gate. `scripts/readme-check.sh`'s
existing "every `make X` mention must resolve to a real target" check only
ever scanned `README.md`, never `docs/decisions/`.

Cross-checked every `` `make <target>` `` mention across all of
`docs/decisions/*.md` against the real `Makefile` `.PHONY` targets:
`tfstate-clean` was the only one missing (20 other ADR-cited targets — e.g.
`artifactory-up/down`, `cilium-up/down`, `harbor-up/down`, `kargo-up`,
`kiali-up/down`, `longhorn-up/down`, `mesh-down`, `inkless-up/down`,
`dr-restore`, `dr-bluegreen-promote`, `tfstate-up/down`, `ci`, `up` — all
resolve correctly).

## Fix

1. Added a real `tfstate-clean` target to the `Makefile` (next to
   `tfstate-up`/`tfstate-down`, `##@ Terraform state (off-cluster S3)`
   section): `cd infra/tfstate && docker compose down -v` — removes the
   `tfstate-garage` container and its `tfstate_data` volume, mirroring the
   `docker compose down -v` pattern `scripts/dr-destroy.sh` already uses for
   the GitLab container. Irreversible; `make tfstate-up` recreates it from
   scratch (recreate-from-code, ADR-0005).
2. **Recurrence guard** (CLAUDE.md's bugfix-must-prevent-recurrence rule):
   extended `scripts/readme-check.sh` (run by `make readme-check`, part of
   `make ci`) with a new section 4 — every `` `make <target>` `` mention
   across `docs/decisions/*.md` must resolve to a real Makefile target, the
   same check `readme-check.sh` already ran for `README.md`, just widened to
   the ADR corpus. Scoped deliberately to `docs/decisions/` only (not all of
   `docs/`) — a broader scan would false-positive on `` `make dr-*` ``
   wildcard prose (`docs/WAYS-OF-WORKING.md`, `ROADMAP.md`) and a hypothetical
   future `` `make dr-chaos` `` example explicitly framed as "a reasonable...
   future ROADMAP item" (`docs/dora-audit-readiness.md`) — neither lives under
   `docs/decisions/`, so the narrower scope avoids both without needing an
   exclusion list.
3. New bats coverage in `tests/drift-detectors.bats`: `"readme-check: fails
   when an ADR names a make target that doesn't exist"`, backed by a new
   `tests/fixtures/readme-check/adr-drift/` fixture tree (README + Makefile
   identical to the existing in-sync fixture; a `docs/decisions/adr-0001-
   example.md` referencing a bogus `` `make bogus-adr-target` ``). Also added
   a `docs/decisions/adr-0001-example.md` fixture (referencing the real
   `make up`) to the existing `in-sync` fixture tree, so the positive path
   (an ADR with a valid reference) is exercised too, not just skipped.
   The existing `"readme-check: passes on the real repo README.md"` test
   already re-runs the script against this repo's real `docs/decisions/`
   tree with no `ROOT` override — it now doubles as the direct regression
   test proving the real ADR corpus is drift-free post-fix.

`make ci` passes (verified locally with `bats`/`yq` installed; other
locally-skipped tools — `helm`, `kustomize`, `kubeconform`, `terraform`,
`shellcheck`, `yamllint` — are unavailable in this remote sandbox and were
confirmed to produce an identical set of pre-existing, unrelated failures on
a clean `main` checkout before this change, via `git stash`/`make ci`/`git
stash pop`; this diff introduces zero new failures).

No topology change — no README/`docs/dependency-tree.md` update needed (this
is a Makefile + drift-script + test change only).

## PR

See the PR this file was committed alongside (`chore/tfstate-clean-target`).
