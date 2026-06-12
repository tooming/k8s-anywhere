# ADR-0007 — Off-cluster Garage Terraform-state backend

- [x] **ADR-0007 — Off-cluster Garage Terraform-state backend** — Added `docs/decisions/adr-0007-off-cluster-garage-tfstate-backend.md` documenting why a second off-cluster Garage instance is used as the Terraform state backend (avoids the cluster→state bootstrap loop), the `generate "backend"` choice over `remote_state` (Garage compatibility), the explicit disabling of state locking, and the relationship to ADRs 0001/0002/0003/0005. Linked from `docs/decisions/README.md`.
