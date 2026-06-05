# region and env settings, mirroring same structure as GCP side for consistency

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "deployment environment"
  type        = string
  default     = "dev"
}

# no project ID on AWS, account is the project
# using project_name just to keep naming consistent across resources
variable "project_name" {
  description = "used for naming all resources"
  type        = string
  default     = "nexcloud"
}

# defining VPC range as a variable so its easy to change without hunting through files
variable "vpc_cidr" {
  description = "IP range for the whole VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# sensitive so terraform never prints it in logs
# actual value lives in tfvars which is gitignored
variable "db_password" {
  description = "RDS postgres password"
  type        = string
  sensitive   = true
}