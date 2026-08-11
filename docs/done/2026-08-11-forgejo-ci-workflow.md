# Port `.gitlab-ci.yml` → `.forgejo/workflows/build-sign-push.yml`

Port `.gitlab-ci.yml` → `.forgejo/workflows/build-sign-push.yml` — same
build → `cosign sign` → push-to-Harbor job (ADR-0011/ADR-0024). Verify live (ADR-0004):
a real pipeline run must push a genuinely signed image to Harbor, not just parse.
Prerequisite: previous item.

This is migration stage 3 of 6 in the "GitLab → Forgejo migration" list
(ROADMAP.md, ADR-0035).

## What's here

- `.forgejo/workflows/build-sign-push.yml` — a straight port of the predecessor
  pipeline's two jobs (`build-and-push`, `sign-image`) to Forgejo Actions
  (GitHub-Actions-compatible) syntax:
  - `build-and-push`: builds `gitops/apps/demo/Dockerfile`, pushes
    `library/hello:<short-sha>` and `:latest` (via `docker tag`, not a second
    build — the two tags share one digest) to Harbor at
    `harbor.127.0.0.1.nip.io:8080`.
  - `sign-image`: `needs: build-and-push`; cosign-signs the short-SHA tag using
    the same digest-pinned `bitnami/cosign` image the predecessor pipeline used.
  - Both jobs set `timeout-minutes` from the start (this repo's own established
    guard for CI hangs — see below).
- `tests/forgejo-ci.bats` — structural coverage mirroring `tests/capstone.bats`'s
  existing predecessor-pipeline checks: jobs exist, `needs:` ordering, no
  hardcoded credentials, single `docker build` + `docker tag` (latest aliases the
  signed digest, doesn't rebuild it), same cosign digest pin, no mention of the
  rejected git host (ADR-0035).
- `scripts/workflow-timeout-check.sh` + `workflow-timeout-sync-hook.sh` extended to
  also scan `.forgejo/workflows/*.yml`, not just `.github/workflows/*.yml` — the
  same hung-job failure mode this check already guards against applies here too,
  arguably worse: this lab's `forgejo-runner` is a single long-lived container
  (`forgejo/docker-compose.yml`), not a fleet of ephemeral hosted runners, so a
  hung job strands the only runner for every subsequent CI run, not just one job
  slot. New fixture coverage in `tests/drift-workflow-timeout-check.bats`
  (`tests/fixtures/workflow-timeout-check/forgejo-only-{in-sync,drift}/`).
- `scripts/lint.sh` extended to yamllint `.forgejo/` alongside `.github/` — it's
  real CI workflow YAML, not a docker-compose file, so it gets the same lint
  coverage `.github/workflows/` already has.

## Design differences from the predecessor pipeline (deliberate, not oversights)

GitHub/Forgejo Actions' `services:` schema (image, credentials, env, ports,
volumes, options) has no command-override field, unlike the predecessor
pipeline's Docker-in-Docker *service*, which passed `--insecure-registry` as a
container command override. Rather than invent a non-standard YAML extension
that might not be supported, `build-and-push` runs Docker-in-Docker manually
inside a single `--privileged` job container (start `dockerd` as a background
step, wait for the socket, then build/push) — a well-known, schema-legal pattern
for this exact problem. Similarly, Forgejo Actions secrets have no "File type"
variant the way the predecessor pipeline's platform did (every secret is a
plain string), so `sign-image`'s first step writes the `COSIGN_KEY` secret to a
temp file itself instead of relying on a platform-provided temp path.

## Verification (ADR-0004)

This is the item's own explicit requirement, stated plainly: **a real pipeline
run must push a genuinely signed image to Harbor, not just parse — that has NOT
happened.** This clusterless remote session has no live Forgejo instance, no
registered `forgejo-runner`, and no live Harbor to run this workflow against
(Terraform for stage 2 has been authored but not `apply`'d either — no live
Forgejo instance exists to configure yet). What *was* verified: the YAML is
well-formed and structurally matches the predecessor pipeline's shape
(`tests/forgejo-ci.bats`), and it does not weaken the `verify-image-signatures`
Kyverno policy's assumptions (same digest-based signing logic).

**Specifically unverified, each flagged inline in the workflow file's own
header comment too:**
1. `container.options: --privileged` — whether the `forgejo-runner`'s
   `config.yml` (gitignored, not yet committed — a future `make forgejo-runner-up`
   task) permits privileged containers at all.
2. `actions/checkout@v4` — whether it resolves through Forgejo's default
   actions-proxy/mirror the way this assumes.
3. Manually starting `dockerd --insecure-registry=...` inside a privileged
   container — whether this actually reaches a working, signable state the same
   way the predecessor pipeline's dind service did.

Rollback path: revert this PR — the file is purely additive, not referenced by
any live automation (the predecessor pipeline, still untouched, is what actually
builds/pushes capstone images today). Follow-up: the next live-cluster session
that stands up `forgejo-runner` (via the not-yet-built `make forgejo-runner-up`)
should run this workflow for real, fix whatever the three items above surface,
and update this record.

## PR

(filled in after PR creation)
