# regional cluster spreads nodes across all three zones automatically
# autoscaling handles capacity — no manual node management needed

resource "google_container_cluster" "nexcloud_gke" {
  name     = "nexcloud-gke-${var.environment}"
  location = var.region
  deletion_protection = false

  network    = google_compute_network.nexcloud_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  # Google creates a default node pool we can't customize properly
  # easier to just delete it and make our own below
  remove_default_node_pool = true
  initial_node_count       = 1
  


  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"


  }

  # nodes sit behind private IPs — nobody should hit them directly
  # keeping endpoint public so we can still use kubectl from laptop
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # lets pods talk to GCP services without hardcoding any keys
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# where the actual work happens
# e2-standard-2 is the sweet spot for dev — cheap but not painfully slow
resource "google_container_node_pool" "nexcloud_nodes" {
  name       = "nexcloud-node-pool-${var.environment}"
  location   = var.region
  cluster    = google_container_cluster.nexcloud_gke.name

  # letting Google babysit the nodes so we don't have to
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  node_config {
    machine_type = "e2-standard-2"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = var.environment
      project     = "nexcloud"
    }
  }
}