variable "deployment" {
  description = "Name of the deployment; {joint,staging,prod,integration}"
}

variable "signin_domain" {
  description = "Domain of the frontend of the deployment; will be used for TLS certificates; e.g. www.staging.signin.service.gov.uk"
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

variable "redis_cache_size" {
  default = "cache.t2.small"
}

variable "truststore_password" {}

locals {
  root_domain = "${replace(var.signin_domain, "/www[.]/", "")}"
}

variable "wildcard_cert_arn" {
  default = "ACM cert arn for wildcard of signin_domain"
}

variable "logit_api_key" {
  description = "Api key used for writing to the logit.io stack"
}

variable "logit_elasticsearch_url" {
  description = "URL for logit.io elasticsearch, format: $guid-es.logit.io"
}

variable "cronitor_prometheus_config_url" {
  description = "URL for the Cronitor check for the Prometheus config updater script"
}
