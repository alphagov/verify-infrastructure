resource "aws_cloudwatch_log_group" "self_service" {
  name = local.service
}
