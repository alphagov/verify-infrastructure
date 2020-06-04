resource "aws_route53_zone" "cluster" {
  name = "${var.cluster}.${var.domain}."

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_route53_record" "lb" {
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "${var.cluster}.${var.domain}."
  type    = "A"

  alias {
    name                   = aws_lb.cluster.dns_name
    zone_id                = aws_lb.cluster.zone_id
    evaluate_target_health = false
  }
}
