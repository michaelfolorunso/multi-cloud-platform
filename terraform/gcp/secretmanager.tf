# storing sensitive stuff here instead of hardcoding anywhere
# app fetches secrets at runtime — nothing sensitive in the codebase

resource "google_secret_manager_secret" "db_password" {
  secret_id = "nexcloud-db-password-${var.environment}"

  replication {
    auto {}
  }
}

# actual secret value — terraform stores this but never prints it
resource "google_secret_manager_secret_version" "db_password_value" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

# service account for the app to use
# this is what talks to GCP services on behalf of the app
resource "google_service_account" "nexcloud_app_sa" {
  account_id   = "nexcloud-app-sa-${var.environment}"
  display_name = "NexCloud App Service Account"
  description  = "used by the app pods to access GCP services"
}

# lets the app service account read secrets — nothing more
resource "google_secret_manager_secret_iam_member" "app_secret_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.nexcloud_app_sa.email}"
}