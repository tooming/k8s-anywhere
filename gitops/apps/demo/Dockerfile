# Thin wrapper on the public HotROD image so the capstone GitLab CI pipeline has
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
FROM jaegertracing/example-hotrod:2.20.0
LABEL org.opencontainers.image.title="k8s-lab hello demo"
LABEL org.opencontainers.image.description="HotROD OTel demo — capstone pipeline artifact"
