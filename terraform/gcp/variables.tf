# GCP project and region settings
# These values are passed in from the terraform.tfvars file

variable "project_id" {
  description = "The GCP project ID for NexCloud"
  type        = string
}

variable "region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone within the region"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}