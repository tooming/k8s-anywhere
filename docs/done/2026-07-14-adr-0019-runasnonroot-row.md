# ADR-0019 amendment — add `add-default-runasnonroot` to the Initial ClusterPolicy set table

🟢 **ADR-0019 amendment — add `add-default-runasnonroot` to the Initial ClusterPolicy
set table** (CHARTER Core Values §"Decisions written down, rejected options off-limits";
docs-only drift — ADR-0019 §"Initial ClusterPolicy set" lists 4 policies but
`gitops/kyverno/policies/` now has 5: `add-default-runasnonroot.yaml` was added after the
Harbor migration (`auto/harbor-application`) closed an admission gap — `goharbor` charts
set container-level `runAsNonRoot` but not pod-level, which `require-pod-security-restricted`
checks at the pod level; this 5th mutate policy injects the missing pod-level field.
`tests/kyverno-add-default-runasnonroot.bats` correctly tests it, but the ADR table
remains stale (only lists the original 4). No prerequisites — executor may pick up
immediately.) Added a row to the ADR-0019 "Initial `ClusterPolicy` set" table for
`add-default-runasnonroot`; updated "All four policies" to "All five policies"; also
corrected an adjacent stale "The four initial ClusterPolicies" mention in the same
file's "Files this ADR changes" table (found while fixing the primary table). No code
changes, no bats changes — the policy and its test file already existed. `make ci`
passes.

## PR

(opened alongside this entry)
