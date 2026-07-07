# O2 PSS per-scope coverage loop bats

(CHARTER **Objective O2**, due **2026-09-30**; O2 PSS recurrence guard — prevents a future namespace
from gaining PSA enforce labels without coverage in either
`tests/securitycontext.bats` (the frozen monolith) or a
`tests/securitycontext-<scope>.bats` per-scope file. **No prerequisites —
executor may pick up immediately (pick up after `auto/o2-np-coverage-loop`
if both are available).** Add a new `@test` to `tests/drift-detectors.bats`
(NOT the frozen monolith): title `"every PSA-labelled namespace has
securitycontext test coverage"`; the body iterates all `namespace.yaml`
files under `gitops/` that contain `pod-security.kubernetes.io/enforce:`
using `grep -rl`; for each file derives the namespace name from the
directory path; asserts that EITHER `grep -q "<ns>" tests/securitycontext.bats`
finds a `@test` referencing that namespace OR a
`tests/securitycontext-<ns>.bats` file exists (check file existence with
`-f`); fails with a clear message naming the uncovered namespace. Handle
the `apps/` sub-path (`apps/capstone/namespace.yaml` → namespace `capstone`)
and the `data/rabbitmq/namespace.yaml` sub-path (namespace `data` — covered
by `securitycontext-data.bats`) correctly. Verify at executor pickup that
the assertion passes for every existing namespace.yaml before committing.
`make ci` must pass. `docs/done/` entry required.
(auto/o2-pss-coverage-loop)

## PR

<!-- filled in after PR creation -->
