terraform {
  required_version = ">= 1.5"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# The oci provider itself is configured by the Terragrunt live unit (generate
# "provider" block, matching how infra/live/local/{argocd,gitlab} inject their
# providers) — this module only declares the required_providers entry.

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.availability_domain_number
}

data "oci_core_images" "arm_image" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "cluster" {
  compartment_id = var.compartment_id
  cidr_block     = "10.20.0.0/16"
  display_name   = "${var.cluster_name}-vcn"
  dns_label      = replace(var.cluster_name, "-", "")
}

resource "oci_core_internet_gateway" "cluster" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.cluster.id
  display_name   = "${var.cluster_name}-igw"
}

resource "oci_core_default_route_table" "cluster" {
  manage_default_resource_id = oci_core_vcn.cluster.default_route_table_id
  display_name               = "${var.cluster_name}-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.cluster.id
  }
}

# Explicit security list (not the implicit VCN default) so the SSH + k3s API rules
# are self-documenting and reviewable in this file, not inferred from OCI defaults.
resource "oci_core_security_list" "cluster" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.cluster.id
  display_name   = "${var.cluster_name}-security-list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = var.api_port
      max = var.api_port
    }
  }
}

resource "oci_core_subnet" "cluster" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.cluster.id
  cidr_block        = "10.20.0.0/24"
  display_name      = "${var.cluster_name}-subnet"
  dns_label         = "subnet"
  security_list_ids = [oci_core_security_list.cluster.id]
  route_table_id    = oci_core_vcn.cluster.default_route_table_id
  dhcp_options_id   = oci_core_vcn.cluster.default_dhcp_options_id
}

resource "oci_core_instance" "cluster" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad.name
  display_name        = var.cluster_name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.cluster.id
    assign_public_ip = true
    hostname_label   = var.cluster_name
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.arm_image.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  timeouts {
    create = "20m"
  }
}

# k3s has no first-class Terraform provider — pull the kubeconfig off the instance
# once cloud-init finishes and merge it into the local kubeconfig under a distinct
# context (oracle-<cluster_name>), matching k3d-cluster's approach for the
# localhost backend and satisfying the infra/live/README.md output contract.
resource "null_resource" "kubeconfig" {
  depends_on = [oci_core_instance.cluster]

  triggers = {
    cluster_name = var.cluster_name
    instance_id  = oci_core_instance.cluster.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      ssh_opts="-o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ${var.ssh_private_key_path}"
      # Bounded retry (60 * 5s = 300s): an unbounded `until` here would hang
      # `terraform apply` forever if the instance never comes up (OCI out-of-capacity,
      # a cloud-init failure, wrong SSH key) -- fail loudly with a diagnosable error
      # instead of hanging silently.
      i=0
      until ssh $ssh_opts ubuntu@${oci_core_instance.cluster.public_ip} 'test -f /etc/rancher/k3s/k3s.yaml'; do
        i=$((i + 1))
        if [ "$i" -ge 60 ]; then
          echo "ERROR: instance ${oci_core_instance.cluster.public_ip} did not become SSH-reachable with a ready /etc/rancher/k3s/k3s.yaml within 300s -- check the OCI console's instance serial console for boot/cloud-init failures" >&2
          exit 1
        fi
        sleep 5
      done
      scp $ssh_opts ubuntu@${oci_core_instance.cluster.public_ip}:/etc/rancher/k3s/k3s.yaml /tmp/${var.cluster_name}-k3s.yaml
      sed -i "s#127.0.0.1#${oci_core_instance.cluster.public_ip}#" /tmp/${var.cluster_name}-k3s.yaml
      sed -i "s#: default#: oracle-${var.cluster_name}#g" /tmp/${var.cluster_name}-k3s.yaml
      mkdir -p "$HOME/.kube"
      KUBECONFIG="$HOME/.kube/config:/tmp/${var.cluster_name}-k3s.yaml" kubectl config view --flatten > /tmp/${var.cluster_name}-merged.yaml
      mv /tmp/${var.cluster_name}-merged.yaml "$HOME/.kube/config"
      rm -f /tmp/${var.cluster_name}-k3s.yaml
      kubectl config use-context "oracle-${var.cluster_name}"
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    # Also unset the users entry -- the create-time sed renames cluster, context,
    # AND user to the same "oracle-<name>" string (k3s.yaml's default kubeconfig
    # uses "default" for all three), so leaving it out here left a stale credential
    # entry behind on every destroy.
    command = "kubectl config delete-context oracle-${self.triggers.cluster_name} 2>/dev/null || true; kubectl config delete-cluster oracle-${self.triggers.cluster_name} 2>/dev/null || true; kubectl config unset users.oracle-${self.triggers.cluster_name} 2>/dev/null || true"
  }
}
