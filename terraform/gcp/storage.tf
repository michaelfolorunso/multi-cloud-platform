# storage bucket for file uploads, attachments, backups
# bucket names are global across all of GCP so adding project ID to avoid conflicts

resource "google_storage_bucket" "nexcloud_bucket" {
  name     = "nexcloud-storage-${var.project_id}"
  location = "US"

  # auto delete files after 90 days — no point paying for old junk
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  # versioning protects against accidental deletes and overwrites —
  # recovery is possible without a full backup restore
  versioning {
    enabled = true
  }

  # locks down access to bucket level only
  # per-file permissions get messy real quick
  uniform_bucket_level_access = true
}