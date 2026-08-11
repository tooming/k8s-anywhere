# Forgejo compose stack, additive alongside GitLab

Forgejo compose stack, additive alongside GitLab — `forgejo/docker-compose.yml`
(`forgejo` + `forgejo-runner` services, reuse the existing `nginx` TLS-terminator
pattern from `gitlab/docker-compose.yml`), `make forgejo-up`/`forgejo-down` targets,
`tests/forgejo-compose.bats`. Zero risk to the current CI path — GitLab is untouched.
No prerequisites, executor may pick up immediately.

This is migration stage 1 of 6 in the "GitLab → Forgejo migration" list
(ROADMAP.md, ADR-0035). GitLab keeps running unmodified; Forgejo stands up
side-by-side (ports 3300/2223, distinct from GitLab's 8929/2222) so both
stacks can run concurrently during the migration window. Not wired into
`make up`'s bootstrap chain; not yet the live git source anything points at.

## Note on this record

The implementation landed in PR #1105 and merged directly to `main`, but
that PR did not check off the ROADMAP.md item or add this `docs/done/`
record as STEP 6 of `routines/executor.prompt.md` requires. This file and
the corresponding ROADMAP.md `[x]` closes that bookkeeping gap — the
underlying work was verified present and correct (`forgejo/docker-compose.yml`,
`scripts/forgejo-env-ensure.sh`, `scripts/forgejo-admin-ensure.sh`, the
`forgejo-up`/`forgejo-down` Makefile targets, and `tests/forgejo-compose.bats`
all confirmed to exist on `main` at the time of this record) before marking
it done, per ADR-0004 (verify before asserting).

## PR

Implementation: [#1105](https://github.com/tooming/k8s-anywhere/pull/1105)
Bookkeeping fix: this PR.
