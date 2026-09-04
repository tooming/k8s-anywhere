# Cilium agent Prometheus metrics + O5 CNI dashboard

Enable Cilium agent Prometheus metrics (`prometheus.enabled: true`, port 9962) in
`gitops/platform/cilium.yaml`; add Alloy pod-discovery scrape config
(`discovery.relabel "cilium_agent"` + `prometheus.scrape "cilium_agent"`) to
`gitops/platform/observability-alloy.yaml` targeting the Cilium DaemonSet at its
node IP (hostNetwork: true) on port 9962; extend
`gitops/observability/networkpolicy/allow-alloy-egress-external.yaml` with a TCP
9962 ipBlock egress rule (mirrors the kubelet/cAdvisor :10250 rule); add
`grafana/dashboards/lab-cilium.json` ("Lab — Cilium (CNI)") with five real
Mimir-datasource panels: DaemonSet ready replicas, ArgoCD sync state, total endpoint
count, policy count, and packet drop rate timeseries. Extend `tests/cilium.bats`
with observability assertions; add Cilium coverage block to
`tests/dashboard-coverage.bats`; update `docs/dependency-tree.md` with Cilium
metrics note. Satisfies CHARTER Objective O5 (every always-on component has a
real-metric Grafana dashboard) for the CNI layer. (RFC #358, ADR-0014, ADR-0004)

## PR

https://github.com/tooming/k8s-anywhere/pull/367
