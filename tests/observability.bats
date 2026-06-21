#!/usr/bin/env bats
# Clusterless checks for the observability gap-filler dashboards (ArgoCD,
# Envoy Gateway, Garage). These assert structural integrity — dashboard file
# exists, panel count, no fabricated/placeholder data (ADR-0004), and that
# docs/dependency-tree.md is updated to mention each dashboard.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- Lab — ArgoCD (GitOps) dashboard -----------------------------------------

@test "lab-argocd.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-argocd.json" ]
}

@test "lab-argocd.json has uid lab-argocd-gitops" {
  run grep -q '"uid": "lab-argocd-gitops"' "$REPO/grafana/dashboards/lab-argocd.json"
  [ "$status" -eq 0 ]
}

@test "lab-argocd.json has at least 12 panels" {
  count=$(grep -c '"type":' "$REPO/grafana/dashboards/lab-argocd.json")
  [ "$count" -ge 12 ]
}

@test "lab-argocd.json uses Mimir datasource for all metric panels" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-argocd.json"
  [ "$status" -eq 0 ]
}

@test "lab-argocd.json queries argocd_app_info for per-app sync state" {
  run grep -q 'argocd_app_info' "$REPO/grafana/dashboards/lab-argocd.json"
  [ "$status" -eq 0 ]
}

@test "lab-argocd.json queries argocd_app_sync_total for sync rate" {
  run grep -q 'argocd_app_sync_total' "$REPO/grafana/dashboards/lab-argocd.json"
  [ "$status" -eq 0 ]
}

@test "lab-argocd.json queries argocd_app_reconcile_duration_seconds_bucket for reconcile heatmap" {
  run grep -q 'argocd_app_reconcile_duration_seconds_bucket' "$REPO/grafana/dashboards/lab-argocd.json"
  [ "$status" -eq 0 ]
}

@test "lab-argocd.json queries argocd_git_request_duration_seconds_bucket for repo-server latency" {
  run grep -q 'argocd_git_request_duration_seconds_bucket' "$REPO/grafana/dashboards/lab-argocd.json"
  [ "$status" -eq 0 ]
}

@test "lab-argocd.json includes an ApplicationSet controller panel" {
  run grep -q 'argocd-applicationset-controller' "$REPO/grafana/dashboards/lab-argocd.json"
  [ "$status" -eq 0 ]
}

@test "lab-argocd.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-argocd.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md mentions lab-argocd.json" {
  run grep -q 'lab-argocd' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

# --- Lab — Envoy Gateway (Ingress) dashboard -----------------------------------------

@test "lab-envoy.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-envoy.json" ]
}

@test "lab-envoy.json has uid lab-envoy-gateway" {
  run grep -q '"uid": "lab-envoy-gateway"' "$REPO/grafana/dashboards/lab-envoy.json"
  [ "$status" -eq 0 ]
}

@test "lab-envoy.json has at least 10 panels" {
  count=$(grep -c '"type":' "$REPO/grafana/dashboards/lab-envoy.json")
  [ "$count" -ge 10 ]
}

@test "lab-envoy.json uses Mimir datasource for all metric panels" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-envoy.json"
  [ "$status" -eq 0 ]
}

@test "lab-envoy.json queries envoy_http_downstream_rq for request rate" {
  run grep -q 'envoy_http_downstream_rq' "$REPO/grafana/dashboards/lab-envoy.json"
  [ "$status" -eq 0 ]
}

@test "lab-envoy.json queries envoy_cluster_upstream for upstream health" {
  run grep -q 'envoy_cluster_upstream' "$REPO/grafana/dashboards/lab-envoy.json"
  [ "$status" -eq 0 ]
}

@test "lab-envoy.json queries controller_runtime_reconcile_total for controller metrics" {
  run grep -q 'controller_runtime_reconcile_total' "$REPO/grafana/dashboards/lab-envoy.json"
  [ "$status" -eq 0 ]
}

@test "lab-envoy.json queries latency histogram for p50/p95/p99" {
  run grep -q 'envoy_http_downstream_rq_time_bucket' "$REPO/grafana/dashboards/lab-envoy.json"
  [ "$status" -eq 0 ]
}

@test "lab-envoy.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-envoy.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md mentions lab-envoy.json" {
  run grep -q 'lab-envoy' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

@test "observability-alloy.yaml has envoy_gateway_controller scrape block" {
  run grep -q 'envoy_gateway_controller' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-alloy.yaml has envoy_proxy scrape block for data-plane stats" {
  run grep -q 'envoy_proxy' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

# --- Lab — Garage S3 (Object Storage) dashboard -----------------------------------------

@test "lab-garage.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-garage.json" ]
}

@test "lab-garage.json has uid lab-garage-storage" {
  run grep -q '"uid": "lab-garage-storage"' "$REPO/grafana/dashboards/lab-garage.json"
  [ "$status" -eq 0 ]
}

@test "lab-garage.json has at least 10 panels" {
  count=$(grep -c '"type":' "$REPO/grafana/dashboards/lab-garage.json")
  [ "$count" -ge 10 ]
}

@test "lab-garage.json uses Mimir datasource for all metric panels" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-garage.json"
  [ "$status" -eq 0 ]
}

@test "lab-garage.json queries garage_bucket_count for bucket stats" {
  run grep -q 'garage_bucket_count' "$REPO/grafana/dashboards/lab-garage.json"
  [ "$status" -eq 0 ]
}

@test "lab-garage.json queries garage_object_count for object stats" {
  run grep -q 'garage_object_count' "$REPO/grafana/dashboards/lab-garage.json"
  [ "$status" -eq 0 ]
}

@test "lab-garage.json queries garage_block_resync for replication lag" {
  run grep -q 'garage_block_resync' "$REPO/grafana/dashboards/lab-garage.json"
  [ "$status" -eq 0 ]
}

@test "lab-garage.json queries garage_storage_bytes for disk usage" {
  run grep -q 'garage_storage_bytes' "$REPO/grafana/dashboards/lab-garage.json"
  [ "$status" -eq 0 ]
}

@test "lab-garage.json queries garage_s3_api for API request rate" {
  run grep -q 'garage_s3_api' "$REPO/grafana/dashboards/lab-garage.json"
  [ "$status" -eq 0 ]
}

@test "lab-garage.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-garage.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md mentions lab-garage.json" {
  run grep -q 'lab-garage' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

@test "observability-alloy.yaml has garage scrape block" {
  run grep -q 'prometheus.scrape "garage"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

# --- Lab — Cloud Control Plane (moto / ACK / KRO) dashboard -------------------

@test "lab-cloud-control-plane.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-cloud-control-plane.json" ]
}

@test "lab-cloud-control-plane.json has uid lab-cloud-control-plane" {
  run grep -q '"uid": "lab-cloud-control-plane"' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json has moto subsection heading" {
  run grep -q 'moto — AWS mock' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json has ACK S3 subsection heading" {
  run grep -q 'ACK S3 — Bucket controller' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json has KRO subsection heading" {
  run grep -q 'KRO — Resource Orchestrator' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json uses Mimir datasource for metric panels" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json uses Loki datasource for log panels" {
  run grep -q '"uid": "loki"' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json queries kube_pod_status_phase for pod health" {
  run grep -q 'kube_pod_status_phase' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json queries container_memory_working_set_bytes for memory" {
  run grep -q 'container_memory_working_set_bytes' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json queries argocd_app_info for sync state" {
  run grep -q 'argocd_app_info' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 0 ]
}

@test "lab-cloud-control-plane.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 1 ]
}

@test "lab-cloud-control-plane.json does not reference unscraped controller-runtime metrics" {
  run grep -qE 'controller_runtime|workqueue_depth' "$REPO/grafana/dashboards/lab-cloud-control-plane.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md mentions lab-cloud-control-plane dashboard" {
  run grep -q 'lab-cloud-control-plane' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

@test "observability-alloy.yaml has external_secrets scrape block" {
  run grep -q 'prometheus.scrape "external_secrets"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-external-secrets.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-external-secrets.json" ]
}

@test "lab-external-secrets.json references externalsecret_sync_calls_total" {
  run grep -q 'externalsecret_sync_calls_total' "$REPO/grafana/dashboards/lab-external-secrets.json"
  [ "$status" -eq 0 ]
}

@test "lab-external-secrets.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-external-secrets.json"
  [ "$status" -eq 1 ]
}

# --- Lab — Grafana Alloy (Collector) self-monitoring dashboard ---------------

@test "observability-alloy.yaml has alloy_self scrape block" {
  run grep -q 'prometheus.scrape "alloy_self"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-alloy.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-alloy.json" ]
}

@test "lab-alloy.json has uid lab-alloy" {
  run grep -q '"uid": "lab-alloy"' "$REPO/grafana/dashboards/lab-alloy.json"
  [ "$status" -eq 0 ]
}

@test "lab-alloy.json uses Mimir datasource" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-alloy.json"
  [ "$status" -eq 0 ]
}

@test "lab-alloy.json references prometheus_sd_discovered_targets" {
  run grep -q 'prometheus_sd_discovered_targets' "$REPO/grafana/dashboards/lab-alloy.json"
  [ "$status" -eq 0 ]
}

@test "lab-alloy.json references prometheus_tsdb_head_samples_appended_total" {
  run grep -q 'prometheus_tsdb_head_samples_appended_total' "$REPO/grafana/dashboards/lab-alloy.json"
  [ "$status" -eq 0 ]
}

@test "lab-alloy.json references alloy_component_evaluation_seconds_sum" {
  run grep -q 'alloy_component_evaluation_seconds_sum' "$REPO/grafana/dashboards/lab-alloy.json"
  [ "$status" -eq 0 ]
}

@test "lab-alloy.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-alloy.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md mentions lab-alloy.json" {
  run grep -q 'lab-alloy' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

# --- Lab — Cluster Health (KSM) dashboard ------------------------------------

@test "lab-ksm.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-ksm.json" ]
}

@test "lab-ksm.json has uid lab-ksm" {
  run grep -q '"uid": "lab-ksm"' "$REPO/grafana/dashboards/lab-ksm.json"
  [ "$status" -eq 0 ]
}

@test "lab-ksm.json uses Mimir datasource" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-ksm.json"
  [ "$status" -eq 0 ]
}

@test "lab-ksm.json references kube_pod_status_phase" {
  run grep -q 'kube_pod_status_phase' "$REPO/grafana/dashboards/lab-ksm.json"
  [ "$status" -eq 0 ]
}

@test "lab-ksm.json references kube_state_metrics_build_info" {
  run grep -q 'kube_state_metrics_build_info' "$REPO/grafana/dashboards/lab-ksm.json"
  [ "$status" -eq 0 ]
}

@test "lab-ksm.json references kube_deployment_status_replicas_available" {
  run grep -q 'kube_deployment_status_replicas_available' "$REPO/grafana/dashboards/lab-ksm.json"
  [ "$status" -eq 0 ]
}

@test "lab-ksm.json references kube_persistentvolumeclaim_status_phase" {
  run grep -q 'kube_persistentvolumeclaim_status_phase' "$REPO/grafana/dashboards/lab-ksm.json"
  [ "$status" -eq 0 ]
}

@test "lab-ksm.json references kube_node_status_condition" {
  run grep -q 'kube_node_status_condition' "$REPO/grafana/dashboards/lab-ksm.json"
  [ "$status" -eq 0 ]
}

@test "lab-ksm.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-ksm.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md mentions lab-ksm dashboard" {
  run grep -q 'lab-ksm' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

# --- Lab — Node Vitals (Node Exporter) dashboard -----------------------------

@test "lab-node-exporter.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-node-exporter.json" ]
}

@test "lab-node-exporter.json has uid lab-node-exporter" {
  run grep -q '"uid": "lab-node-exporter"' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

@test "lab-node-exporter.json uses Mimir datasource" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

@test "lab-node-exporter.json references node_cpu_seconds_total" {
  run grep -q 'node_cpu_seconds_total' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

@test "lab-node-exporter.json references node_memory_MemAvailable_bytes" {
  run grep -q 'node_memory_MemAvailable_bytes' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

@test "lab-node-exporter.json references node_filesystem_avail_bytes for disk usage" {
  run grep -q 'node_filesystem_avail_bytes' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

@test "lab-node-exporter.json references node_network_receive_bytes_total for throughput" {
  run grep -q 'node_network_receive_bytes_total' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

@test "lab-node-exporter.json references node_network_transmit_bytes_total for throughput" {
  run grep -q 'node_network_transmit_bytes_total' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

@test "lab-node-exporter.json references node_boot_time_seconds for uptime" {
  run grep -q 'node_boot_time_seconds' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 0 ]
}

@test "lab-node-exporter.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-node-exporter.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md mentions lab-node-exporter dashboard" {
  run grep -q 'lab-node-exporter' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}
