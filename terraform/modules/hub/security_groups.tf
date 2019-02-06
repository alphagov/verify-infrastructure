resource "aws_security_group" "scraped_by_prometheus" {
  name        = "${var.deployment}-scraped-by-prometheus"
  description = "${var.deployment}-scraped-by-prometheus"

  vpc_id = "${aws_vpc.hub.id}"
}

module "scraped_by_prometheus_can_be_scraped_by_prometheus" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.prometheus.id}"
  destination_sg_id = "${aws_security_group.scraped_by_prometheus.id}"

  port = 9100
}
