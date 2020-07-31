resource "aws_service_discovery_service" "app" {
  name = "${local.identifier}-fargate"

  description = "A service to allow Prometheus to discover ${local.identifier}-fargate instances"

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 60
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }
}
