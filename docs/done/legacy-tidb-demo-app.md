# TiDB demo app

- [x] **TiDB demo app** — `gitops/platform/tidb-demo.yaml` (manual-sync ArgoCD Application, git-path `gitops/tidb-demo/`). nginx demo workload in namespace `tidb` reading Vault credentials (`secret/tidb/demo`) via `ExternalSecret tidb-demo-creds`. Envoy HTTPRoute `tidb-demo.127.0.0.1.nip.io`. Grafana dashboard "Lab — TiDB Demo App" (real pod/container metrics). `make tidb-demo-up` / `make tidb-demo-down`. Vault-bootstrap seeding added. Docs updated in README + dependency-tree + stack-health panel.
