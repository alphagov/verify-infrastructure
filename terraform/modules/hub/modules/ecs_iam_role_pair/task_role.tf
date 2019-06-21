# A task role is the role which the containers in an ECS task use to access AWS
# services/resources. I.e. An app can make an S3 api call using its task role.

resource "aws_iam_role" "task" {
  name = "${var.deployment}-${var.service_name}-task"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

output "task_role_arn" {
  value = "${aws_iam_role.task.arn}"
}
