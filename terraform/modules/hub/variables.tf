variable "deployment" {
  description = "Name of the deployment; {joint,staging,prod,integration}"
}

variable "signin_domain" {
  description = "Domain of the frontend of the deployment; will be used for TLS certificates; e.g. www.staging.signin.service.gov.uk"
}

variable "tools_account_id" {
  description = "AWS account id of the tools account, where docker images will be pulled from"
}

variable "number_of_apps" {
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
  root_domain                  = "${replace(var.signin_domain, "/www[.]/", "")}"
  number_of_availability_zones = 3
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

variable "event_emitter_api_gateway_url" {
  description = "URL for Event Emitter API Gateway"
}

variable "zendesk_url" {
  description = "URL for Zendesk"
}

variable "zendesk_username" {
  description = "Username (email address) for Zendesk access"
}

variable "hub_config_image_tag" {}
variable "hub_policy_image_tag" {}
variable "hub_saml_proxy_image_tag" {}
variable "hub_saml_soap_proxy_image_tag" {}
variable "hub_saml_engine_image_tag" {}
variable "hub_frontend_image_tag" {}
variable "hub_metadata_image_tag" {}
