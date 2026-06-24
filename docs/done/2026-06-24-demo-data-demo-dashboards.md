# Lab — `demo` + `data-demo` dashboards (O5 completion)

**Lab — `demo` + `data-demo` dashboards (O5 completion)** (CHARTER **Objective O5**,
due **2026-09-30**; O5 gap — `demo` (HotROD in `lab-demo` namespace) and `data-demo`
(data-layer traffic generators in `data` namespace) are the last two auto-synced
always-on Applications without a `grafana/dashboards/lab-<name>.json`, leaving O5
incomplete before its 2026-09-30 deadline. Two small dashboards bundled (same
KSM/cAdvisor stat-row pattern — no new scrape jobs needed; Alloy already scrapes
KSM and cAdvisor):

- New `grafana/dashboards/lab-demo.json` ("Lab — demo (HotROD)") — demo pod running,
  ArgoCD sync state, memory usage, CPU usage rate. HotROD does not expose Prometheus
  metrics; span/trace data is in `lab-traces.json` (Tempo). No HTTPRoute row needed.

- New `grafana/dashboards/lab-data-demo.json` ("Lab — data-demo (Traffic Generators)") —
  rabbitmq-load running, valkey-load running, ArgoCD sync state, rabbitmq-load memory,
  CPU + memory timeseries for both generators.

- Extended `tests/observability.bats` with 16 new assertions (8 per dashboard).

- Updated `docs/dependency-tree.md` with `demo` and `data-demo` dashboard notes.

## PR

See PR for `auto/demo-data-demo-dashboards`.
