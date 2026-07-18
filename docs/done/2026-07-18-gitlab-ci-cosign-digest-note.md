# Document why `.gitlab-ci.yml`'s cosign sign step only signs one tag (not a bug)

Doc-precision fix discovered while investigating a suspected gap in this run: `.gitlab-ci.yml`'s
`sign-image` job only `cosign sign`s the `$CI_COMMIT_SHORT_SHA` tag, while
`build-and-push` also pushes `:latest` — the tag `gitops/apps/capstone/deployment.yaml`
and `rollout.yaml` actually reference. At first glance this looks like the deployed
`:latest` image would never carry a valid signature, which would matter once Kyverno's
`verify-image-signatures` `ClusterPolicy` (currently `Audit`/`Ignore`, gated on the
`auto/cosign-enforce-flip` ROADMAP item) flips to `Enforce`.

**Verified this is NOT a bug.** cosign's signature is attached to the image's content
digest (pushed as a `sha256-<digest>.sig` tag in the same registry repository), not to
the tag name used at sign time. `build-and-push`'s `docker tag` step makes `:latest` an
alias for the exact same digest as the just-built `:$CI_COMMIT_SHORT_SHA` image (not a
separate build) — so cosign's one signing call already produces a signature both tags
resolve to, and Kyverno's `verifyImages` mechanism verifies by resolving the deployed
image reference to its digest first, the same way. Signing both tags explicitly would be
redundant, not a correctness fix.

Since this non-obvious digest-vs-tag distinction could mislead a future contributor (it
briefly did mislead this run's own investigation, before checking cosign's actual
signing/verification model rather than assuming tag-based association), documented it
explicitly:

- Added a comment to `.gitlab-ci.yml`'s `sign-image` job explaining the digest-based
  reasoning and explicitly warning against "fixing" it into redundant dual-tag signing.
- Added two `tests/capstone.bats` assertions: one guarding the premise this reasoning
  depends on (`docker tag`, not a second `docker build`, is what creates `:latest` —
  if the pipeline is ever changed to build `:latest` separately, this assumption
  silently breaks and `:latest` would deploy unsigned), and one confirming the
  `sign-image` job signs the `$CI_COMMIT_SHORT_SHA` tag.

`bats tests/capstone.bats`: 37/37 pass. `make ci`: green (same pre-existing local-only
`yq`/`jq` tag-filter failures as `main`, unrelated to these files).

## PR

https://github.com/tooming/k8s-anywhere/pull/497
