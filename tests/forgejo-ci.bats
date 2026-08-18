#!/usr/bin/env bats
# ROADMAP "GitLab → Forgejo migration" item 3: .forgejo/workflows/build-sign-push.yml
# must exist and carry the same build → sign → push shape as tests/capstone.bats
# already asserts for the CI pipeline file this ports from — same structural,
# clusterless pattern (grep-based file-content assertions), no live Forgejo/
# forgejo-runner instance needed to confirm the file is shaped correctly.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WF="$REPO/.forgejo/workflows/build-sign-push.yml"
}

@test "build-sign-push.yml exists under .forgejo/workflows/" {
  [ -f "$WF" ]
}

@test "build-sign-push.yml declares build-and-push and sign-image jobs" {
  grep -q '^  build-and-push:' "$WF"
  grep -q '^  sign-image:' "$WF"
}

@test "build-and-push job is pinned to the exact patch docker:29.7.2 (2026-08-17: pin-what's-running, docker:29 floating tag closed)" {
  run grep -q 'image: docker:29\.7\.2$' "$WF"
  [ "$status" -eq 0 ]
}

@test "build-and-push job does not pin the superseded floating docker:29 tag" {
  run grep -q 'image: docker:29$' "$WF"
  [ "$status" -eq 1 ]
}

@test "sign-image needs build-and-push (job ordering, mirrors the predecessor pipeline's stages)" {
  run sed -n '/^  sign-image:/,/^  [a-zA-Z]/p' "$WF"
  [ "$status" -eq 0 ]
  [[ "$output" == *"needs: build-and-push"* ]]
}

@test "build-sign-push.yml every job sets an explicit timeout-minutes" {
  run sed -n '/^  build-and-push:/,/^  sign-image:/p' "$WF"
  [[ "$output" == *"timeout-minutes:"* ]]
  run sed -n '/^  sign-image:/,$p' "$WF"
  [[ "$output" == *"timeout-minutes:"* ]]
}

@test "build-sign-push.yml references HARBOR_USER and HARBOR_PASSWORD secrets (no plaintext)" {
  grep -q 'secrets.HARBOR_USER' "$WF"
  grep -q 'secrets.HARBOR_PASSWORD' "$WF"
}

@test "build-sign-push.yml contains no hardcoded credential values" {
  # No bare 'password:'/'HARBOR_PASSWORD:'-style literal assignment outside of
  # the ${{ secrets.* }} expression form.
  run grep -E '(HARBOR_(USER|PASSWORD)|COSIGN_KEY):\s*[^$ ]' "$WF"
  [ "$status" -eq 1 ]
}

@test "build-and-push creates :latest via docker tag (same digest as the pushed short-SHA tag), not a separate build" {
  run grep -q 'docker tag ' "$WF"
  [ "$status" -eq 0 ]
  # Only one docker build invocation should exist in the whole workflow.
  run bash -c "grep -c 'docker build ' '$WF'"
  [ "$output" = "1" ]
}

@test "sign-image signs the short-SHA tag (the digest both tags share)" {
  run grep -q 'cosign sign' "$WF"
  [ "$status" -eq 0 ]
  run sed -n '/^  sign-image:/,$p' "$WF"
  [[ "$output" == *'sha="${GITHUB_SHA:0:8}"'* ]]
}

@test "build-sign-push.yml is digest-pinned to the same cosign image as the predecessor pipeline" {
  grep -q 'bitnami/cosign@sha256:db4d480f96235bca0433be791ea156cf51c3c7b62874618d8fcacecc86555aee' "$WF"
}

@test "build-sign-push.yml does not name the rejected git host (ADR-0035 guard parity)" {
  ! grep -qi 'gitlab' "$WF"
}

@test "build-and-push checks out via a plain git clone, not actions/checkout@v4" {
  # Found live 2026-08-17: Forgejo's default actions-proxy resolves marketplace
  # actions (including actions/checkout) by git-cloning them from data.forgejo.org
  # at run time, and that host was consistently unreachable from this lab's job
  # containers — every run failed at "Set up job" before any real logic executed.
  # See the checkout step's own comment for the full story.
  run grep -q 'uses: actions/checkout@v4' "$WF"
  [ "$status" -eq 1 ]
  grep -q 'git clone --no-checkout' "$WF"
}

@test "build-and-push's plain-git-clone checkout targets Forgejo's internal HTTP endpoint" {
  grep -q '@forgejo:3000/\${GITHUB_REPOSITORY}\.git' "$WF"
}

@test "build-and-push's checkout step checks out the exact triggering commit" {
  grep -q 'git checkout "\$GITHUB_SHA"' "$WF"
}

@test "build-sign-push.yml references the CHECKOUT_TOKEN secret (no plaintext)" {
  grep -q 'secrets.CHECKOUT_TOKEN' "$WF"
}

@test "REGISTRY keeps the real harbor.127.0.0.1.nip.io hostname (Envoy Gateway's HTTPRoute matches on the Host header — swapping the hostname breaks routing even if the TCP connection itself succeeds, found live 2026-08-18)" {
  grep -q 'REGISTRY: harbor.127.0.0.1.nip.io:8080' "$WF"
  run grep -q 'REGISTRY:.*host\.docker\.internal' "$WF"
  [ "$status" -eq 1 ]
}

@test "both jobs override harbor.127.0.0.1.nip.io's own resolution via /proc/net/route (portable — sign-image's Photon OS base has no ip command), not a second host.docker.internal hostname" {
  count="$(grep -c "awk '\\\$2 == \"00000000\"" "$WF")"
  [ "$count" -eq 2 ]
  count2="$(grep -c 'harbor\.127\.0\.0\.1\.nip\.io" >> /etc/hosts' "$WF")"
  [ "$count2" -eq 2 ]
}

@test "build-and-push wraps every network-facing docker command in retry_cmd (login, build, both pushes) — found live 2026-08-18, the port to Forgejo Actions had silently dropped this from the predecessor pipeline" {
  grep -q 'retry_cmd sh -c .echo "\$HARBOR_PASSWORD"' "$WF"
  # --build-arg "REGISTRY=$REGISTRY" (2026-08-18): gitops/apps/demo/Dockerfile's
  # FROM now pulls its base image from Harbor's own mirror instead of docker.io
  # directly — see that Dockerfile's own comment for the full story.
  grep -q 'retry_cmd docker build --build-arg "REGISTRY=\$REGISTRY" -t "\$REGISTRY/\$IMAGE_NAME:\$sha"' "$WF"
  grep -q 'retry_cmd docker push "\$REGISTRY/\$IMAGE_NAME:\$sha"' "$WF"
  grep -q 'retry_cmd docker push "\$REGISTRY/\$IMAGE_NAME:latest"' "$WF"
}

@test "build-and-push does not wrap the plain 'docker tag' call in retry_cmd (local operation, no network involved — same as the predecessor pipeline)" {
  run grep -q 'retry_cmd docker tag' "$WF"
  [ "$status" -eq 1 ]
  grep -q '^          docker tag "\$REGISTRY/\$IMAGE_NAME:\$sha" "\$REGISTRY/\$IMAGE_NAME:latest"$' "$WF"
}

# 2026-08-18: docker.io's auth-token endpoint was the one consistently-unreachable
# hop in the whole pipeline — retry_cmd's 6 attempts never once got through it,
# while every other step (including Login to Harbor a few lines earlier in the
# same job) was solid. Mirrored the base image into Harbor once instead
# (`crane copy docker.io/... harbor.../library/example-hotrod:2.20.0`) and
# repointed the Dockerfile's FROM there — see gitops/apps/demo/Dockerfile's own
# comment for the full story.
@test "gitops/apps/demo/Dockerfile pulls its base image from Harbor's own mirror, not docker.io directly" {
  DOCKERFILE="$REPO/gitops/apps/demo/Dockerfile"
  [ -f "$DOCKERFILE" ]
  run grep -q '^FROM jaegertracing/example-hotrod:2.20.0$' "$DOCKERFILE"
  [ "$status" -eq 1 ]
  grep -q '^ARG REGISTRY=harbor.127.0.0.1.nip.io:8080$' "$DOCKERFILE"
  grep -q '^FROM \${REGISTRY}/library/example-hotrod:2.20.0$' "$DOCKERFILE"
}

# 2026-08-17, run #26: sign-image's "Resolve $REGISTRY's host" step (identical to
# build-and-push's own, which works fine there) failed with `/etc/hosts:
# Permission denied` — bitnami/cosign defaults to a non-root UID (1001), unlike
# build-and-push's docker:29.7.2 (root by default). This was the *first* time
# sign-image ever actually ran (every prior run failed inside build-and-push
# before sign-image's `needs:` dependency let it start), so this bug had never
# been reachable until now.
@test "sign-image's container runs as root (bitnami/cosign defaults to non-root, breaks writing /etc/hosts)" {
  run sed -n '/^  sign-image:/,/^    steps:/p' "$WF"
  [ "$status" -eq 0 ]
  [[ "$output" == *"options: --user root"* ]]
}
