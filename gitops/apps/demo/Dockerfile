# Thin wrapper on the public HotROD image so the capstone CI pipeline has
# something to build + push to the in-lab Harbor registry. The image itself
# is unchanged; the point is the pipeline mechanics (build → tag → push → pull).
#
# Pinned :latest -> 2.20.0 (2026-07-28, executor currency check): PR #796 fixed this
# same floating tag in gitops/apps/demo/deployment.yaml (a separate, directly-deployed
# reference to the same upstream image) but missed this Dockerfile's own FROM line --
# the actual base this pipeline builds from. Verified via the real Docker Hub API that
# 2.20.0's digest (sha256:0ad3ffcc697069a691b404c6a989f22965ddbe72b7c2542a29196a31474efbbe)
# still matches :latest's current digest exactly, same version already verified for
# deployment.yaml. Flip condition: revisit when jaegertracing publishes a newer tag.
#
# FROM points at Harbor's own mirror of this image, not docker.io directly — found
# live 2026-08-18: docker.io's auth-token endpoint (auth.docker.io) was unreachable
# from inside the Forgejo Actions job container often enough that retry_cmd's 6
# attempts (build-sign-push.yml) never once got through, while the same job's
# "Login to Harbor" step (a few lines earlier in the same workflow) reliably
# succeeded — the job container's path to the in-lab Harbor is solid, its path to
# docker.io isn't. Mirrored once via `crane copy docker.io/jaegertracing/example-
# hotrod:2.20.0 harbor.../library/example-hotrod:2.20.0` run from the Mac host
# (whose network path to docker.io IS reliable), removing the flaky hop from the
# pipeline entirely instead of continuing to retry into it. REGISTRY is passed as a
# build-arg so this stays in sync with the workflow's own REGISTRY env var rather
# than hardcoding a second copy of it here.
ARG REGISTRY=harbor.127.0.0.1.nip.io:8080
FROM ${REGISTRY}/library/example-hotrod:2.20.0
LABEL org.opencontainers.image.title="k8s-lab hello demo"
LABEL org.opencontainers.image.description="HotROD OTel demo — capstone pipeline artifact"
