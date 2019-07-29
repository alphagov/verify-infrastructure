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
