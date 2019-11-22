variable "deployment" {
  description = "Name of the deployment; {staging,prod,integration}"
}

variable "domain" {
  description = "Domain on which the app is hosted"
  default     = ""
}

variable "ssl_certificate_arn" {
  description = "ARN for the SSL certificate"
  default     = ""
}

variable "accessible_from_cidrs" {
  description = "Accessible from CIDRs"
  type        = "list"
  default     = []
}

data "aws_caller_identity" "account" {}

variable "db_instance_class" {
  description = "Instance class for the Self Service RDS DB"
  default     =  "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Storage allocation for the Self Service RDS DB"
  default     = 50
}

variable "db_multi_az" {
  description = "Whether Self Service RDS DB is multi AZ"
  default     = false
}

variable "db_backup_retention_period"{
  description = "Self Service DB backup retention period"
  default     = 7
}

variable "db_username" {
  description = "Self Service DB username"
  default     = "postgres"
}

variable "db_command" {
  description = "Command to run during the DB migration step, e.g. `bundle exec rails db:<value>`"
  default     = "migrate"
}

variable "asset_host" {
  description = "Host where the static assets are hosted"
  default     = "gds-verify-self-service-assets.s3.amazonaws.com"
}

variable "image_digest" {
  default = ""
}

variable "hub_environments" {
  description = "JSON string of hub environments and the config metadata buckets"
  default     = ""
}

variable "hub_host" {
  description = "The host for the Verify hub"
  default     = "signin.service.gov.uk"
}

variable "additional_buckets" {
  description = "Additional bucket ARNs which the app will publish to"
  type        = "list"
  default     = []
}
