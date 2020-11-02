output "internal_subnet_ids" {
  value = aws_subnet.internal.*.id
}

output "vpc_id" {
  value = aws_vpc.hub.id
}

output "can_connect_to_container_vpc_endpoint" {
  value = aws_security_group.can_connect_to_container_vpc_endpoint.id
}

output "public_subnet_ids" {
  value = aws_subnet.ingress.*.id
}

output "config_fargate_v2_lb_sg_id" {
  value = module.config_fargate_v2.lb_sg_id
}

output "fargate_ecs_cluster_id" {
  value = aws_ecs_cluster.fargate-ecs-cluster.id
}

output "hub_fargate_microservice_security_group_id" {
  value = aws_security_group.hub_fargate_microservice.id
}

output "hub_apps_private_dns_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.hub_apps.id
}

output "ingress_https_lb_listener_arn" {
  value = aws_lb_listener.ingress_https.arn
}

output "metadata_ecs_execution_role_arn" {
  value = module.metadata_ecs_roles.execution_role_arn
}

output "metadata_task_security_group_id" {
  value = aws_security_group.metadata_task.id
}

output "ingress_metadata_lb_target_group_arn" {
  value = aws_lb_target_group.ingress_metadata.arn
}