# Remove exact-duplicate bats assertions between component files and their securitycontext-<scope> split files

Bugfix/hardening item, not a ROADMAP item: reached via `executor.prompt.md`
STEP 6b / ROADMAP rule #9 — this run's sixth cycle. Cycles 1–5 each fixed a
distinct real issue (doc drift, two Kyverno policy gaps, a Terraform-comment
verification) or filed an honest empty-sweep record. Cycle 6 tried yet
another fresh lens: a repo-wide search for exact-duplicate `@test` titles
across every `tests/*.bats` file (`grep -h '^@test "' tests/*.bats | sort |
uniq -d`) — a check for the specific duplication class CLAUDE.md's
"kill duplication" guidance names, at a scope no prior cycle this run had
checked.

## Finding

Seven `@test` titles were exact duplicates, byte-identical in logic, across
three component pairs — each general component file (`tests/cert-manager.bats`,
`tests/harbor.bats`, `tests/keda.bats`) still carried 1–3 PSS/Application-wiring
assertions that were *also* present in that component's dedicated
`tests/securitycontext-<scope>.bats` file, targeting the exact same source
file:

- `cert-manager.bats` / `securitycontext-cert-manager.bats`: "cert-manager
  namespace enforces PSS restricted", "...has enforce-version: latest",
  "cert-manager-extras Application exists".
- `harbor.bats` / `securitycontext-harbor.bats`: "harbor namespace has
  enforce-version: latest".
- `keda.bats` / `securitycontext-keda.bats`: "keda namespace enforces PSS
  restricted", "...has enforce-version: latest", "keda-extras Application
  exists".

`scripts/securitycontext-tests-check.sh`'s own header establishes the
intended architecture: per-scope PSS tests belong in a dedicated
`tests/securitycontext-<scope>.bats` file, never appended to the shared
`tests/securitycontext.bats` monolith. Spot-checking components without this
duplication (`velero.bats`, `trivy-operator.bats` — zero PSS mentions in
their own file) confirmed the dedicated split file is meant to be the *sole*
home for these assertions; cert-manager/harbor/keda were the exceptions,
most likely because their own general test files already had these checks
from before the split-file pattern existed, and the migration never removed
the now-redundant originals.

One more title collision exists (`"build-and-push job does not pin the
superseded floating docker:29 tag"` in both `cosign-bootstrap.bats` and
`forgejo-ci.bats`) but was verified NOT a real duplicate — the two target
different files (`.gitlab-ci.yml` vs `.forgejo/workflows/build-sign-push.yml`,
both pinned to the same tag per the GitLab→Forgejo CI migration), so this one
is intentional parallel coverage and was left untouched.

## Fix

Removed the seven duplicate `@test` blocks from the three general component
files, leaving a one-line comment at each removal site pointing to the
canonical `securitycontext-<scope>.bats` copy so a future reader doesn't
mistake the removal for a coverage drop. No assertion logic changed —
every removed test's exact check still runs, just from a single location
instead of two.

## Verification

`bats tests/cert-manager.bats tests/harbor.bats tests/keda.bats
tests/securitycontext-cert-manager.bats tests/securitycontext-harbor.bats
tests/securitycontext-keda.bats` — 188/188 pass. Full `make ci` with the
real `mikefarah/yq` binary on `PATH` — zero `not ok`, exit 0.

## PR

https://github.com/tooming/k8s-anywhere/pull/1355
