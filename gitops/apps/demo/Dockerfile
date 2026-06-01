# Thin wrapper on the public HotROD image so the capstone GitLab CI pipeline has
# something to build + push to the in-lab Artifactory registry. The image itself
# is unchanged; the point is the pipeline mechanics (build → tag → push → pull).
FROM jaegertracing/example-hotrod:latest
LABEL org.opencontainers.image.title="k8s-lab hello demo"
LABEL org.opencontainers.image.description="HotROD OTel demo — capstone pipeline artifact"
