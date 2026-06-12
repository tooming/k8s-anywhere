# Vault & Secrets dashboard

- [x] **Vault & Secrets dashboard** — Added `grafana/dashboards/lab-vault.json`: a "Lab — Vault & Secrets" Grafana dashboard with 11 panels covering pod-running status, memory, CPU, restart counts, and ArgoCD sync state for both Vault and External Secrets Operator. All panels use real KSM/cAdvisor/ArgoCD metrics already scraped by Alloy — no fabricated data (ADR-0004). Delivered through Grafana native Git Sync (ADR-0006). Covers the "Add Grafana dashboards for always-on components lacking them" backlog item. (PR #TBD)
