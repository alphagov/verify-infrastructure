resource "aws_cloudwatch_log_group" "self_service" {
  name = local.service
}

resource "aws_cloudwatch_event_rule" "scheduler_rule" {
  name                = "${var.deployment}-${local.service}-cert-expiry-scheduler-rule"
  description         = "Run send_cert_expiry_reminder_emails task at a scheduled time"
  # scheduled to run every day at 2am
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "scheduler_target" {
  target_id = "${var.deployment}-${local.service}-cert-expiry-scheduler-target"
  rule      = aws_cloudwatch_event_rule.scheduler_rule.name
  arn       = aws_ecs_cluster.cluster.arn
  role_arn  = "${aws_iam_role.scheduled_task_cloudwatch.arn}"

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.scheduler_task_def.arn
  }
}
