variable "deployment" {
  description = "Name of the deployment; {joint,staging,prod,integration}"
}

variable "domain" {
  description = "Root domain of the deployment; will be used for TLS certificates; e.g. staging.signin.service.gov.uk"
}

variable "tools_account_id" {
  description = "AWS account id of the tools account, where docker images will be pulled from"
}

variable "number_of_availability_zones" {
  default = 2
}

variable "publically_accessible_from_cidrs" {
  default = ["0.0.0.0/0"]
}

variable "truststore_password" {}
