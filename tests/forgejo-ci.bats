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

@test "REGISTRY uses host.docker.internal, not the nip.io host trick (127.0.0.1 means the job container itself, not the VM host)" {
  grep -q 'REGISTRY: host.docker.internal:8080' "$WF"
  run grep -q 'REGISTRY:.*nip\.io' "$WF"
  [ "$status" -eq 1 ]
}

@test "both jobs resolve host.docker.internal via /proc/net/route (portable — sign-image's Photon OS base has no ip command)" {
  count="$(grep -c "awk '\\\$2 == \"00000000\"" "$WF")"
  [ "$count" -eq 2 ]
}
