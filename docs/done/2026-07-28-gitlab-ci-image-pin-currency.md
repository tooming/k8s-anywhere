# Fix a broken `bitnami/cosign:2` pin and a 2-year-stale `docker:24` pin in `.gitlab-ci.yml`

CHARTER **Core Values** §"Everything as code" + general CI hygiene. Architect-role
fallback (`executor.prompt.md` STEP 6b) after the "Now / next" lane again came up
fully gated on standing maintainer-confirmation issues #631/#632/#633 (re-checked
this cycle — still no confirmation comments on any of the three); PRs #815/#816
already closed this run's other fallback-lane findings.

## What was found

Auditing `.gitlab-ci.yml`'s own CI job images (a class not previously swept this
run — prior sweeps covered gitops-deployed workload images and Kyverno's
`disallow-latest-tag` policy, not the GitLab pipeline's own build-time images)
turned up two real, verified problems, checked directly against the Docker Hub API
(not training-data assumption, per ADR-0004):

1. **`bitnami/cosign:2` (the `sign-image` job) is a broken pin.**
   `GET https://hub.docker.com/v2/repositories/bitnami/cosign/tags/2` returns a real
   `404: tag '2' not found`. Bitnami has moved this image to its "Secure Images"
   model, which now only publishes `latest` and content-addressed `sha256-<digest>`
   tags — every numbered tag is gone. Any real GitLab CI run of the `sign-image`
   job would fail at image pull, before ever reaching the `cosign sign` step. This
   is plausibly *why* issue #631 (confirm a signed image was pushed) has sat open
   with zero comments since 2026-07-20 — if the pipeline was ever actually run, this
   job could not have succeeded.
2. **`docker:24` / `docker:24-dind` (the `build-and-push` job + its dind service)
   are 2-years-stale.** The Docker Hub API's own `last_updated` field for tag `24`
   is `2024-07-26` — no security patches in two years — while tag `29` (the
   current major line) shows `last_updated: 2026-07-17` (11 days before this
   check), confirming `24` is no longer receiving updates at all, not merely behind
   by a few patches.

## Why this is a same-run Convert, not another standing gate

Both are CI/build-time image pins, not gitops-deployed cluster workloads —
zero live-cluster blast radius, and this remote session cannot run a real GitLab
pipeline regardless (no live GitLab), so `make ci`'s clusterless bats structural
coverage is the verification ceiling here, same as every other `.gitlab-ci.yml`
change already merged this run's history (e.g. `docs/done/2026-06-17-cosign-ci-sign-step.md`).
The `build-and-push` job's actual command surface (`docker build`/`push`/`tag`/
`login`/`logout`, `DOCKER_HOST`/`DOCKER_TLS_CERTDIR`, dockerd's
`--insecure-registry` flag) is the same extremely stable primitive surface Docker
has kept unchanged across every major release in its history; this session could
not fetch Docker Engine's own major-version release notes directly (moby/moby's
`CHANGELOG.md` and GitHub Releases pages both 404'd/were unreachable from this
sandbox — a known proxy-egress limitation, not evidence either way), so the
"no breaking change" claim here rests on the stability of the commands actually
used, not a fetched changelog — called out explicitly rather than asserted as
independently verified (ADR-0004).

## What changed

- `.gitlab-ci.yml`:
  - `sign-image`'s `image:` → `bitnami/cosign@sha256:db4d480f96235bca0433be791ea156cf51c3c7b62874618d8fcacecc86555aee`
    (the real manifest-list digest behind `bitnami/cosign:latest` as of this audit,
    covering both amd64 and arm64 runners — same digest-pin-when-no-stable-tag-exists
    pattern as the `cloudlena/s3manager` fix, PR #796).
  - `build-and-push`'s `image:` and its dind service: `docker:24`/`docker:24-dind` →
    `docker:29`/`docker:29-dind`.
  - Comments on both recording the audit trail and a flip condition for the next
    re-review.
- `tests/cosign-bootstrap.bats`: updated the now-stale `"sign-image job uses
  bitnami/cosign:2 image"` assertion to check for the digest pin instead; added a
  new assertion pinning `docker:29`/`docker:29-dind` as a recurrence guard.

`make ci` passes locally (all real checks green; `.gitlab-ci.yml` re-validated as
parseable YAML; `bats`/`shellcheck`/`kubeconform`/`kustomize`/`terraform`/`helm`
gracefully skip as designed — none installed in this environment). No topology
change; README/`docs/dependency-tree.md` don't reference either image.

PR: (this run's `arch/gitlab-ci-image-pin-currency` branch)
