# GCP equivalent of ECR — stores all three service images in one repo

resource "google_artifact_registry_repository" "nexcloud" {
  location      = var.region
  repository_id = "nexcloud"
  format        = "DOCKER"
  description   = "NexCloud container images"

  # same cleanup logic as AWS side, no point keeping more than 10
  cleanup_policies {
    id     = "keep-last-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  labels = {
    environment = var.environment
    project     = "nexcloud"
  }
}

# GKE nodes need to pull images from this registry
# reader role is enough, no reason to give write access
resource "google_artifact_registry_repository_iam_member" "gke_pull" {
  location   = google_artifact_registry_repository.nexcloud.location
  repository = google_artifact_registry_repository.nexcloud.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.nexcloud_app_sa.email}"
}