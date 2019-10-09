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
  type = "list"
}

variable "mgmt_accessible_from_cidrs" {
  type = "list"
}

variable "redis_cache_size" {
  default = "cache.t2.small"
}

variable "truststore_password" {}

variable "rp_truststore_enabled" {
  description = "The RP truststore should be disabled if any self-service certs will be used by RPs, since we cannot validate the trust chain for self-signed certs"
  default     = "true"
}

locals {
  root_domain                  = replace(var.signin_domain, "/www[.]/", "")
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

variable "matomo_site_id" {
  description = "Site ID to use for Matomo"
  default     = 1
}

variable "analytics_endpoint" {
  description = "Analytics endpoint"
}

variable "splunk_url" {
  description = "Splunk http event collector endpoint, used by saml-engine"
}

variable "splunk_hostname" {
  description = "Splunk hostname, used by saml-engine's egress proxy"
}

variable "ab_test_file" {
  description = "File containing percentage values for variant and control"
  default     = "deactivated_ab_test.yml"
}

variable "self_service_enabled" {
  description = "Enable the use of the Self Service generated metadata"
  default     = "false"
}

variable "cross_gov_ga_tracker_id" {
  description = "The Google Analytics tracker ID for GOV.UK cross domain analysis"
  default     = ""
}

variable "cross_gov_ga_domain_names" {
  description = "List of (space delimited) domains to automatically enable links and forms for cross-domain analytics"
  default     = "www.gov.uk"
}

variable "hub_config_image_digest" {}
variable "hub_policy_image_digest" {}
variable "hub_saml_proxy_image_digest" {}
variable "hub_saml_soap_proxy_image_digest" {}
variable "hub_saml_engine_image_digest" {}
variable "hub_frontend_image_digest" {}
variable "hub_metadata_image_digest" {}

variable "ecs_agent_image_digest" {}
variable "nginx_image_digest" {}
variable "static_ingress_image_digest" {}
variable "static_ingress_tls_image_digest" {}
variable "beat_exporter_image_digest" {}
variable "cloudwatch_exporter_image_digest" {}
variable "squid_image_digest" {}
variable "metadate_exporter_image_digest" {}
variable "prometheus_image_digest" {}
