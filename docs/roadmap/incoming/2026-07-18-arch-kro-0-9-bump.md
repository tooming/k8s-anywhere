- [ ] 🟡 **Bump KRO chart `0.4.1` → `0.9.x` — verify CRD/instance-scope compatibility
  first** (CHARTER **Core Values** §"Everything as code" + general hardening; RFC #534
  — architect decision 2026-07-18). KRO's latest stable release is `v0.9.2` — five minor
  versions ahead of this lab's `0.4.1` chart pin (`gitops/platform/kro.yaml`). KRO is
  pre-1.0 (`0.x` semver — every minor version is allowed to be breaking), and the
  `v0.9.0` release notes specifically flag "cluster-scoped instance CRDs" — a change
  that may affect the exact mechanism this lab depends on (the `ResourceGraphDefinition`
  in `gitops/kro/rgd-s3bucketclaim.yaml` that generates the `S3BucketClaim` CRD
  `gitops/platform/kro-resources.yaml` instantiates into the `ack-system` namespace).
  **No prerequisites — executor may pick up immediately**, but per RFC #534's
  acceptance criteria the executor MUST fetch the actual KRO CRD definitions at the
  target tag and directly verify whether the generated instance CRD's scope changed
  from `Namespaced` to `Cluster` before bumping — do not assume a clean drop-in, same
  bar the Kargo `1.2.3 → 1.6.4` bump already applied to its own multi-minor jump. If
  the scope did change, update `gitops/platform/kro-resources.yaml`'s
  `destination.namespace` (and any other namespace-scoped assumption) accordingly and
  document exactly what changed. If verification finds the breaking change is real and
  non-trivial to accommodate cleanly, split the actual version bump into a smaller
  documented item rather than force a risky bump in one PR (ROADMAP rule #9). Diff the
  chart's `values.yaml` for any key this repo's Application sets; add/extend bats
  coverage pinning the chart version. `make ci` must pass. PR body must document the
  specific CRD/scope verification performed and the ADR-0004 caveat that this remote
  clusterless session cannot verify the `S3BucketClaim` instance actually reconciles
  cleanly against a live ACK S3 Bucket + moto backend post-bump — call out the
  rollback path (revert the chart pin; note a scope-related `kro-resources.yaml` edit
  must revert in lockstep if one was needed). `docs/done/` entry required. Closes #534.
  (auto/kro-bump-0-9)
