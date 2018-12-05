variable "deployment" {
  description = "Name of the deployment; {joint,staging,prod,integration}"
}

variable "domain" {
  description = "Root domain of the deployment; will be used for TLS certificates; e.g. staging.signin.service.gov.uk"
}

variable "number_of_availability_zones" {
  default = 2
}
