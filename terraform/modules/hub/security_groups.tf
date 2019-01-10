resource "aws_security_group" "egress_via_proxy" {
  name        = "${var.deployment}-egress-via-proxy"
  description = "${var.deployment}-egress-via-proxy"

  vpc_id = "${aws_vpc.hub.id}"
}

resource "aws_security_group" "scraped_by_prometheus" {
  name        = "${var.deployment}-scraped-by-prometheus"
  description = "${var.deployment}-scraped-by-prometheus"

  vpc_id = "${aws_vpc.hub.id}"
}

resource "aws_security_group_rule" "egress_via_proxy_egress_to_egress_proxy_lb_over_nonpriv_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 8080
  to_port   = 8080

  # source is destination for egress rules
  source_security_group_id = "${aws_security_group.egress_proxy_lb.id}"
  security_group_id        = "${aws_security_group.egress_via_proxy.id}"
}

module "scraped_by_prometheus_can_be_scraped_by_prometheus" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.prometheus.id}"
  destination_sg_id = "${aws_security_group.scraped_by_prometheus.id}"

  port = 9100
}
