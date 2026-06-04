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

# reserve a block of IPs for Google's managed services to use
resource "google_compute_global_address" "private_ip_range" {
  name          = "nexcloud-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.nexcloud_vpc.id
}

# the actual private connection between our VPC and Google services
# for a private IP in our network to be used by Google services
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.nexcloud_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}