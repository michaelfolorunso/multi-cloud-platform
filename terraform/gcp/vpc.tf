# Custom mode VPC — auto subnets disabled so we control IP ranges
# All NexCloud resources live here, nothing exposed to public internet by default

resource "google_compute_network" "nexcloud_vpc" {
  name                    = "nexcloud-vpc-${var.environment}"
  auto_create_subnetworks = false
  description             = "NexCloud private VPC network"
}

# Main subnet for GKE cluster
# This is where our Kubernetes nodes will run
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "nexcloud-gke-subnet-${var.environment}"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.nexcloud_vpc.id

  # Secondary ranges for Kubernetes pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.48.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.52.0.0/20"
  }
}