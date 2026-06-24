# storage bucket for file uploads and app assets
# bucket names are globally unique across all of AWS, project name + account ID suffix handles that
resource "aws_s3_bucket" "nexcloud" {
  bucket = "${var.project_name}-storage-${var.environment}"

  tags = {
    Name        = "${var.project_name}-storage-${var.environment}"
    Environment = var.environment
  }
}

# blocking all public access,app talks to S3 through IAM roles, not public URLs
resource "aws_s3_bucket_public_access_block" "nexcloud" {
  bucket = aws_s3_bucket.nexcloud.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# versioning so we can recover accidentally deleted or overwritten files
resource "aws_s3_bucket_versioning" "nexcloud" {
  bucket = aws_s3_bucket.nexcloud.id

  versioning_configuration {
    status = "Enabled"
  }
}

# encrypt everything at rest
# AES256 uses AWS-managed keys — production would use aws:kms
# with a customer-managed key for full decryption audit trails
resource "aws_s3_bucket_server_side_encryption_configuration" "nexcloud" {
  bucket = aws_s3_bucket.nexcloud.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# auto delete old files after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "nexcloud" {
  bucket = aws_s3_bucket.nexcloud.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {} # empty filter means all objects are affected by the expiration rule

    expiration {
      days = 90
    }
  }
}