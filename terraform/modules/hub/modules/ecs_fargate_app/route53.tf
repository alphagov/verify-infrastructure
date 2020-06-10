resource "aws_route53_zone" "app" {
  name = "${var.app}.${var.domain}."

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_route53_record" "lb" {
  zone_id = aws_route53_zone.app.zone_id
  name    = "${var.app}.${var.domain}."
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = false
  }
}
