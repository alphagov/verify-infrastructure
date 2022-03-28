variable "deployment" {
  description = "Name of the deployment; {joint,staging,prod,integration}"
}

variable "signin_domain" {
  description = "Domain of the frontend of the deployment; will be used for TLS certificates; e.g. www.staging.signin.service.gov.uk"
}

variable "tools_account_id" {
  description = "AWS account id of the tools account, where docker images will be pulled from"
}

variable "number_of_frontend_apps" {
  type    = number
  default = 2
}

variable "number_of_config_apps" {
  type    = number
  default = 2
}

variable "number_of_analytics_apps" {
  type    = number
  default = 2
}

variable "number_of_saml_soap_proxy_apps" {
  type    = number
  default = 2
}

variable "number_of_metadata_apps" {
  type    = number
  default = 2
}

variable "number_of_saml_proxy_apps" {
  type    = number
  default = 2
}

variable "number_of_saml_engine_apps" {
  type    = number
  default = 2
}

variable "number_of_policy_apps" {
  type    = number
  default = 2
}

variable "number_of_egress_proxy_apps" {
  type    = number
  default = 2
}

variable "number_of_static_ingress_apps" {
  type    = number
  default = 2
}

variable "number_of_prometheus_apps" {
  default = 3
}

variable "policy_memory_limit_mb" {
  type    = number
  default = 4 * 1024
}

variable "saml_proxy_memory_limit_mb" {
  type    = number
  default = 4 * 1024
}

variable "prometheus_volume_size" {
  default = 120
}

variable "publically_accessible_from_cidrs" {
  type = list
}

variable "mgmt_accessible_from_cidrs" {
  type = list
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

variable "cls_destination_arn" {
  description = "ARN of the CSLS destination to send logs to"
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

variable "publish_hub_config_enabled" {
  description = "Enable endpoints to expose config service certificates"
  default     = "false"
}

variable "certificates_config_cache_expiry" {
  description = "Sets the expiry time of cache for certificates in saml-proxy, saml-engine and saml-soap-proxy"
  default     = "1m"
}

variable "hub_frontend_log_level" {
  description = "Log level for Puma and Frontend applications"
  default     = "warn"
}

variable "hub_config_log_level" {
  default = "INFO"
}

variable "hub_policy_log_level" {
  default = "INFO"
}

variable "hub_saml_proxy_log_level" {
  default = "INFO"
}

variable "hub_saml_soap_proxy_log_level" {
  default = "INFO"
}

variable "hub_saml_engine_log_level" {
  default = "INFO"
}

variable "metadata_exporter_environment" {
  description = "Metadata Exporter environment"
  default     = "development"
}

variable "jvm_options" {
  default = "-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=80"
}

variable "throttling_enabled" {
  description = "Toggles the throttling of IDP traffic on frontend"
  default     = "false"
}

variable "manage_metadata" {
  description = "A flag to deploy the metadata and associated infrastructure. Used while moving metadata release to a separate pipeline. Use 1 for true and 0 for false"
  default     = 1
}

variable "hub_config_image_digest" {}
variable "hub_policy_image_digest" {}
variable "hub_saml_proxy_image_digest" {}
variable "hub_saml_soap_proxy_image_digest" {}
variable "hub_saml_engine_image_digest" {}
variable "hub_frontend_image_digest" {}

variable "ecs_agent_image_digest" {}
variable "nginx_image_digest" {}
variable "static_ingress_fargate_image_digest" {}
variable "static_ingress_tls_fargate_image_digest" {}
variable "cloudwatch_exporter_image_digest" {}
variable "squid_image_digest" {}
variable "metadate_exporter_image_digest" {}
variable "prometheus_image_digest" {}
