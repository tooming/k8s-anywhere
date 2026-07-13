# `infra/modules/oracle-k3s-cluster` Terraform module

RFC #377 item 1 — ADR-0027 is the binding spec. OCI Terraform provider setup; an
Ampere A1 compute instance resource sized to the Always Free shape (2 OCPU / 12 GB per
ADR-0027 — uses `required` variables for compartment/tenancy/availability-domain, no
live-account defaults, so `terraform validate`/`fmt` pass in clusterless `make ci`
without real OCI credentials); cloud-init installing k3s
(`curl -sfL https://get.k3s.io | sh -`); a `local-exec` provisioner that `scp`s
`/etc/rancher/k3s/k3s.yaml` off the instance and merges it into `~/.kube/config` under
a distinct context name (`oracle-<cluster_name>`, never colliding with `k3d-k8s-lab`
— see ADR-0027 §"Contract compliance"). Outputs: `cluster_name`, `kube_context`,
`api_endpoint`, matching `infra/live/README.md`'s contract exactly (same names as
`k3d-cluster`'s outputs).

Provisions its own VCN, subnet, internet gateway, default route table, and an explicit
security list (SSH 22 + the k3s API port, not the implicit VCN default) — self-contained,
no dependency on any other module.

Not wired into a Terragrunt live unit yet — that's RFC #377 item 2
(`infra/live/oracle/{cluster,argocd,gitlab}/terragrunt.hcl`), tracked as a separate
ROADMAP item since it depends on this module existing first.

**Validation note:** this sandbox's egress policy blocks `registry.terraform.io`, so
only `terraform fmt -check` could run locally (clean). `terraform validate`/`tflint`
depend on GitHub Actions' `terraform` CI job, which has full registry access.

## PR

https://github.com/tooming/k8s-anywhere/pull/379
