variable "deployment" {
  description = "Name of the deployment; {staging,prod,integration}"
}

variable "domain" {
  description = "Domain on which the app is hosted"
}

variable "ssl_certificate_arn" {
  description = "ARN for the SSL certificate"
}

variable "accessible_from_cidrs" {
  description = "Accessible from CIDRs"
  type = "list"
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
