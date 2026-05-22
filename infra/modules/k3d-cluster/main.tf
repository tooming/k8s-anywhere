terraform {
  required_version = ">= 1.5"
  required_providers {
    null  = { source = "hashicorp/null", version = "~> 3.2" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Rendered k3d config — written next to the Terragrunt run so you can inspect it.
resource "local_file" "k3d_config" {
  filename = "${path.cwd}/k3d-config.generated.yaml"
  content = templatefile("${path.module}/k3d-config.yaml.tftpl", {
    cluster_name    = var.cluster_name
    servers         = var.servers
    agents          = var.agents
    api_port        = var.api_port
    http_port       = var.http_port
    https_port      = var.https_port
    disable_traefik = var.disable_traefik
  })
}

# k3d has no first-class Terraform provider, so we drive its CLI.
# Create is idempotent (skips if the cluster already exists); destroy removes it.
resource "null_resource" "cluster" {
  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = "k3d cluster get ${var.cluster_name} >/dev/null 2>&1 || k3d cluster create --config '${local_file.k3d_config.filename}'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.triggers.cluster_name}"
  }
}
