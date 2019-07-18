output "internal_subnet_ids" {
  value = "${aws_subnet.internal.*.id}"
}

output "vpc_id" {
  value = "${aws_vpc.hub.id}"
}

output "aws_lb_listener_ingress_https" {
  value = "${aws_lb_listener.ingress_https.arn}"
}
