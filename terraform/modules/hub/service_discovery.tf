resource "aws_service_discovery_private_dns_namespace" "hub_apps" {
  name        = "hub.local"
  description = "Hub app instances"
  vpc         = "${aws_vpc.hub.id}"
}

resource "aws_service_discovery_service" "frontend" {
  name = "frontend"

  description = "A service to allow Prometheus to discover frontend instances"

  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.hub_apps.id}"

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
