include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/k3d-cluster"
}

inputs = {
  servers              = 1
  agents               = 1
  api_port             = 6445
  http_port            = 8080
  # https_port kept at 8446 (not the default 8443) — no functional reason left
  # to avoid 8443 (the DR frontdoor that reserved it was removed 2026-09-07, no
  # replacement), but changing a working port assignment isn't worth the churn.
  https_port           = 8446
  # disable_traefik left at the module's default (false, ADR-0040 supersedes ADR-0008):
  # Traefik is now the lab's sole north-south ingress controller, so it must NOT be
  # disabled here. This explicit `= true` override was a leftover from the pre-ADR-0040
  # Envoy Gateway era (when k3s's bundled Traefik was redundant) that PR #1451 missed —
  # found live 2026-09-06 attempting a fresh `make up`: `coredns-nip-io-rewrite` timed
  # out because no `traefik` Service ever appeared in `kube-system` on a freshly
  # created cluster, since this override was still disabling it at k3d creation time.
  # Cilium (ADR-0014) was removed entirely 2026-09-07, no replacement — k3s's
  # bundled Flannel CNI + kube-router NetworkPolicy controller is the CNI now.
  # `disable_default_cni` MUST stay `false` (the k3d default) or the cluster comes
  # up with no CNI at all and every pod sits in ContainerCreating forever — see
  # the variable's own warning in infra/modules/k3d-cluster/variables.tf.
  disable_default_cni  = false
}
