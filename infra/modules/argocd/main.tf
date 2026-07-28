# Provider constraint audit (issue #791, architect decision 2026-07-28, this run):
# `~> 2.17` locked out the 3.x line forever (a `~>` pessimistic constraint never
# auto-picks up a new major). Verified directly against upstream before widening
# (ADR-0004 — not from training-data assumption): the hashicorp/helm v3.0.0
# CHANGELOG's only schema-relevant break is `set`/`set_list`/`set_sensitive`
# moving from blocks to a list-of-objects representation — this module's
# `helm_release.argocd` uses none of those attributes. The current v3.2.0
# `helm_release` schema doc was fetched directly and confirms every attribute
# this module sets (name, repository, chart, version, namespace,
# create_namespace, values, wait, timeout) is present, unchanged in meaning and
# type. Widened to `~> 3.0`; next flip condition: revisit when a helm provider
# 4.x line ships (mirrors the ADR re-evaluation-log flip-condition pattern).
terraform {
  required_version = ">= 1.5"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

# Installs the upstream argo-cd Helm chart as a tracked Terraform release.
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [file("${path.module}/values.yaml")]

  wait    = true
  timeout = 600
}
