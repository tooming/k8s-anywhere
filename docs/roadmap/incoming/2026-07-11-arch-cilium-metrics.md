- [ ] 🟡 **Cilium agent Prometheus metrics + O5 CNI dashboard** (CHARTER **Objective O5**,
  RFC #358 — architect decision 2026-07-11). Enable `prometheus.enabled: true` and
  `prometheus.port: 9962` in `gitops/platform/cilium.yaml` `valuesObject` (Hubble stays
  disabled; `hubble.enabled: false` unchanged — 250-400 MB cost excluded from the 12 GB
  budget). Add `discovery.kubernetes "cilium_agent"` + `discovery.relabel "cilium_agent"`
  + `prometheus.scrape "cilium_agent"` blocks to `gitops/platform/observability-alloy.yaml`
  (Cilium DaemonSet uses `hostNetwork: true` in `kube-system`; kubernetes_sd pod discovery
  with `k8s-app=cilium` selector + relabel `__address__` to port 9962; scrape_interval
  30s; inline comment noting target is idle until `make cilium-up` has run at least once).
  Extend `gitops/observability/networkpolicy/allow-alloy-egress-external.yaml` with TCP
  9962 egress to `ipBlock: cidr: 0.0.0.0/0` (mirrors the existing TCP 9100 node-exporter
  and TCP 10250 kubelet/cAdvisor ipBlock rules). New `grafana/dashboards/lab-cilium.json`
  ("Lab — Cilium (CNI)") with five real Mimir-datasource panels: (1) Cilium agent DaemonSet
  ready replicas (`kube_daemonset_status_number_ready{namespace="kube-system",daemonset="cilium"}`);
  (2) ArgoCD sync state (`argocd_app_info{name="cilium"}`); (3) total endpoint count
  (`sum(cilium_endpoint_state)`); (4) policy count stat (`cilium_policy_count`); (5) packet
  drop rate timeseries (`rate(cilium_drop_count_total[5m])` by `reason`). All panels use
  `X-Scope-OrgID: lab` (ADR-0004 — no fabricated data). Extend `tests/dashboard-coverage.bats`
  with Cilium assertion (`lab-cilium.json` exists; `"uid": "mimir"` present). Add bats
  assertions to `tests/observability.bats` or a new `tests/cilium.bats`: `cilium_agent`
  scrape block present in `observability-alloy.yaml`; `lab-cilium.json` exists; dashboard
  references `cilium_policy_count`; no placeholder data. Update `docs/dependency-tree.md`
  with a one-line Cilium metrics scrape note. `docs/done/` entry required. `make ci` must
  pass. Single-PR preferred; split only if PR exceeds ~400 lines. **This is a 🟢 Green-tier
  executor item once the RFC is groomed by the planner.** (auto/cilium-agent-metrics)
