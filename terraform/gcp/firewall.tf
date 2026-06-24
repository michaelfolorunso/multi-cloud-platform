# broad internal access for dev — in production this would be
# tightened to only the ports each service actually needs

resource "google_compute_firewall" "allow_internal" {
  name    = "nexcloud-allow-internal-${var.environment}"
  network = google_compute_network.nexcloud_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  # only traffic from within our own VPC subnet gets through
  source_ranges = ["10.0.0.0/20"]
}

resource "google_compute_firewall" "allow_web" {
  name    = "nexcloud-allow-web-${var.environment}"
  network = google_compute_network.nexcloud_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  # anyone on the internet can hit our web ports
  # everything else stays locked
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "nexcloud-allow-health-checks-${var.environment}"
  network = google_compute_network.nexcloud_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }

  # Google's load balancer needs these ranges to check if our app is alive
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}