output "internal_subnet_ids" {
  value = "${aws_subnet.internal.*.id}"
}

output "vpc_id" {
  value = "${aws_vpc.hub.id}"
}

output "can_connect_to_container_vpc_endpoint" {
  value = "${aws_security_group.can_connect_to_container_vpc_endpoint.id}"
}

output "cloudwatch_vpc_endpoint" {
  value = "${aws_security_group.cloudwatch_vpc_endpoint.id}"
}
