# postgres instance for all app data
# db-f1-micro is the smallest available — fine for dev, cheap too

resource "google_sql_database_instance" "nexcloud_db" {
  name             = "nexcloud-db-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.region
  deletion_protection = false
  depends_on = [google_service_networking_connection.private_vpc_connection]    # this line is required for Cloud SQL to get a private IP in our VPC

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }

    # only allow connections from within our VPC
    # nothing from the public internet touches this
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.nexcloud_vpc.id
    }

    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }
}

# the actual database inside the instance
resource "google_sql_database" "nexcloud_database" {
  name     = "nexcloud"
  instance = google_sql_database_instance.nexcloud_db.name
}

# app user — not using root because that's just asking for trouble
resource "google_sql_user" "nexcloud_user" {
  name     = "nexcloud_app"
  instance = google_sql_database_instance.nexcloud_db.name
  password = var.db_password
}