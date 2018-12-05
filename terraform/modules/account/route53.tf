resource "aws_route53_zone" "public_root" {
  name = "${var.domain}"

  tags {
    Deployment = "${var.deployment}"
  }
}
