# Pin `gitops/apps/demo/Dockerfile`'s floating hotrod base image tag

CHARTER **Core Values** §"Everything as code" + general CI hygiene. Janitor/
architect-role fallback (`executor.prompt.md` STEP 6b) continuing this cycle's
image/tool-pin currency audit (PRs #815/#817/#818) into build-input Dockerfiles.
"Now / next" remains fully gated on standing maintainer-confirmation issues
#631/#632/#633 (re-checked this cycle — still no confirmation comments on any of
the three).

## What was found

`gitops/apps/demo/Dockerfile`'s `FROM jaegertracing/example-hotrod:latest` line
was still floating — a gap PR #796 (this run) had already fixed for the *same*
upstream image in `gitops/apps/demo/deployment.yaml` (a separate, directly-deployed
reference) but missed here, since this Dockerfile is what `.gitlab-ci.yml`'s
`build-and-push` job actually builds `FROM` to produce `docker-local/hello` — the
artifact that flows through the entire cosign-sign → Kargo-promote → capstone
Rollout pipeline this cycle's other PRs (#817) already repaired. A floating base
tag here means every pipeline rebuild could silently pull a different upstream
image without anyone noticing, undermining the reproducibility of the very
pipeline just fixed.

Neither existing bats test caught this: `tests/capstone.bats`'s "demo Dockerfile is
based on the hotrod image" test only checks the repository name, not the tag; and
`tests/image-pin-demo-storage.bats`'s `:latest` guard (added by PR #796) only greps
`deployment.yaml`, not the Dockerfile — the two files reference the same upstream
image through a different manifest key (`image:` vs `FROM`), so PR #796's guard
never covered this one.

## Why this is a same-run Convert

Verified directly against the Docker Hub API (ADR-0004) that `2.20.0`'s digest
(`sha256:0ad3ffcc697069a691b404c6a989f22965ddbe72b7c2542a29196a31474efbbe`) still
matches `:latest`'s current digest exactly — the same version PR #796 already
verified and pinned for `deployment.yaml`, so this is a known-good, previously
verified tag, not a fresh unknown. Build-time Dockerfile, not a gitops-deployed
workload — zero live-cluster blast radius.

## What changed

- `gitops/apps/demo/Dockerfile`: `FROM jaegertracing/example-hotrod:latest` →
  `:2.20.0`, with a comment recording the audit trail and cross-referencing PR
  #796.
- `tests/capstone.bats`: added a test asserting the Dockerfile pins `2.20.0` and
  does not reference `:latest` — the recurrence guard PR #796 should have added
  here too.

`make ci` passes locally (all real checks green). No topology change;
README/`docs/dependency-tree.md` don't reference the Dockerfile's base-image tag
specifically.

PR: (this run's `arch/demo-dockerfile-hotrod-pin` branch)
