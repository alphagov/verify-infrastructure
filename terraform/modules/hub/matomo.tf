locals {
  volume_name = "shared_www"

  log_format = <<-LOG_FORMAT
  log_format  matomo  '{"ip": "$remote_addr",'
                       '"http_x_forwarded_for": "$http_x_forwarded_for",'
                       '"host": "$host",'
                       '"path": "$request_uri",'
                       '"status": "$status",'
                       '"referrer": "$http_referer",'
                       '"user_agent": "$http_user_agent",'
                       '"length": $bytes_sent,'
                       '"generation_time_milli": $request_time,'
                       '"userid": "$remote_user",'
                       '"request": "$request",'
                       '"msec": "$msec",'
                       '"method": "$request_method",'
                       '"content_type": "$content_type",'
                       '"date": "$time_iso8601"}';

  access_log /dev/stdout matomo;
LOG_FORMAT


  nginx_log_format_base64 = base64encode(local.log_format)
}

resource "aws_kms_key" "matomo" {
  description = "used to encrypt secrets in parameter store for matomo"
}

# resource "aws_kms_alias" "matomo" {
#   name          = "alias/platform-web"
#   target_key_id = aws_kms_key.matomo_web.key_id
# }

resource "aws_lb" "matomo" {
  name               = "matomo" ## TODO: namespace
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.matomo_lb.id]
  subnets            = aws_subnet.ingress.*.id
  idle_timeout       = 300
}

# resource "aws_lb_listener" "matomo_http" {
#   load_balancer_arn = aws_lb.matomo.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"

#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

resource "aws_lb_listener" "matomo_https" {
  load_balancer_arn = aws_lb.matomo.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.mgmt_wildcard.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "🧢"
      status_code  = "200"
    }
  }
}

resource "aws_route53_record" "matomo" {
  zone_id = aws_route53_zone.ingress_www.id
  name    = "analytics.${local.mgmt_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.matomo.dns_name
    zone_id                = aws_lb.matomo.zone_id
    evaluate_target_health = false
  }
}

data "template_file" "matomo_task_def" {
  template = file("${path.module}/files/matomo/matomo-task-def.json")

  vars = {
    nginx_image_identifier          = "${local.tools_account_ecr_url_prefix}-verify-nginx-tls@${var.nginx_image_digest}"
    matomo_config_file_part_one_arn = aws_ssm_parameter.matomo_config_file_part_one.arn
    matomo_config_file_part_two_arn = aws_ssm_parameter.matomo_config_file_part_two.arn
    volume_name                     = local.volume_name
    image_and_tag                   = "${local.tools_account_ecr_url_prefix}-verify-matomo@${var.matomo_image_digest}"
    location_blocks_base64          = base64encode(file("${path.module}/files/matomo/nginx.conf"))
    log_format_base64               = local.nginx_log_format_base64
  }
}

resource "aws_ecs_task_definition" "matomo_task_def" {
  family                   = "matomo"
  container_definitions    = data.template_file.matomo_task_def.rendered
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.matomo_execution.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 2048

  volume {
    name = local.volume_name
  }
}

data "template_file" "matomo_archiving_task_def" {
  template = file("${path.module}/files/matomo/matomo-archiving-def.json")

  vars = {
    matomo_config_file_part_one_arn = aws_ssm_parameter.matomo_config_file_part_one.arn
    matomo_config_file_part_two_arn = aws_ssm_parameter.matomo_config_file_part_two.arn
    image_and_tag                   = "${local.tools_account_ecr_url_prefix}-verify-matomo@${var.matomo_image_digest}"
    cronitor_url                    = var.matomo_archiving_cronitor_url
  }
}

resource "aws_ecs_task_definition" "matomo_archiving_task_def" {
  family                   = "matomo-archiving"
  container_definitions    = data.template_file.matomo_archiving_task_def.rendered
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.matomo_execution.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 2048
}

data "template_file" "matomo_adhoc_task_def" {
  template = file("${path.module}/files/matomo/matomo-adhoc-def.json")

  vars = {
    image_and_tag = "mysql:5"
  }
}

resource "aws_ecs_task_definition" "matomo_adhoc_task_def" {
  family                   = "matomo-adhoc" ## TODO: namespacing?
  container_definitions    = data.template_file.matomo_adhoc_task_def.rendered
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.matomo_execution.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 2048
}

resource "aws_lb_target_group" "matomo" {
  name                 = "matomo" ##TODO: namespace?
  port                 = 8443
  protocol             = "HTTPS"
  vpc_id               = aws_vpc.hub.id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 3
    matcher             = "200-400"
  }
}

resource "aws_lb_listener_rule" "listener" {
  listener_arn = aws_lb_listener.matomo_https.arn
  priority     = 141

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.matomo.arn
  }

  condition {
    host_header {
      values = ["analytics.*"]
    }
  }
}
resource "aws_security_group" "matomo_lb" {
  name        = "matomo-lb"
  description = "Security group for matomo application load balancer"
  vpc_id      = aws_vpc.hub.id
}

resource "aws_security_group_rule" "matomo_lb_ingress_443_gds" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.matomo_lb.id
  cidr_blocks       = var.mgmt_accessible_from_cidrs
}

resource "aws_security_group" "matomo" {
  name        = "matomo-common" # Namespace later???
  description = "Common security group for matomo instances"
  vpc_id      = aws_vpc.hub.id
}

resource "aws_security_group_rule" "matomo_ingress_self" {
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "tcp"

  security_group_id        = aws_security_group.matomo.id
  source_security_group_id = aws_security_group.matomo.id
}

resource "aws_security_group_rule" "matomo_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.matomo.id
}

resource "aws_security_group_rule" "matomo_ingress_all_matomo_lb" {
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "tcp"

  security_group_id        = aws_security_group.matomo.id
  source_security_group_id = aws_security_group.matomo_lb.id
}

resource "aws_security_group_rule" "matomo_lb_egress_all_matomo" {
  type      = "egress"
  from_port = 0
  to_port   = 65535
  protocol  = "all"

  security_group_id        = aws_security_group.matomo_lb.id
  source_security_group_id = aws_security_group.matomo.id
}

resource "aws_ecs_service" "matomo" {
  name            = "matomo"
  cluster         = aws_ecs_cluster.fargate-ecs-cluster.id
  task_definition = aws_ecs_task_definition.matomo_task_def.arn
  desired_count   = 3

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = aws_lb_target_group.matomo.id
    container_name   = "matomo-nginx"
    container_port   = "8443"
  }

  network_configuration {
    security_groups = [
      aws_security_group.matomo_lb.id,
      aws_security_group.matomo.id,
    ]

    subnets = aws_subnet.internal.*.id
  }
}

resource "aws_iam_role" "matomo_execution" {
  name = "matomo-execution"

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

resource "aws_cloudwatch_log_group" "matomo" {
  name = "matomo" #Namespaced???
}

resource "aws_iam_policy" "matomo_web_secrets" {
  name = "matomo-execution-secrets"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/matomo/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:Describe*",
          "kms:Decrypt"
        ],
        "Resource": "${aws_kms_key.matomo.arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource": [
          "${aws_cloudwatch_log_group.matomo.arn}",
          "${aws_cloudwatch_log_group.matomo.arn}/*"
        ]
      }
    ]
  }
EOF

}

resource "aws_iam_role" "matomo_cloudwatch_execution" {
  name = "matomo_cloudwatch_execution"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC

}

resource "aws_iam_role_policy" "allow_run_ecs_tasks" {
  name = "allow-run-ecs-tasks"
  role = aws_iam_role.matomo_cloudwatch_execution.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "*"
        }
    ]
}
DOC

}
resource "aws_cloudwatch_event_target" "matomo_scheduled_archive_task" {
  target_id = "run-matomo-archive-task"
  arn       = aws_ecs_cluster.fargate-ecs-cluster.id
  rule      = aws_cloudwatch_event_rule.every_hour.name
  role_arn  = aws_iam_role.matomo_cloudwatch_execution.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.matomo_archiving_task_def.arn
    launch_type         = "FARGATE"

    network_configuration {
      security_groups = [
        aws_security_group.matomo_lb.id,
        aws_security_group.matomo.id,
      ]

      subnets = aws_subnet.internal.*.id
    }
  }
}

resource "aws_iam_role_policy_attachment" "matomo_execution_matomo_web_secrets" {
  role       = aws_iam_role.matomo_execution.name
  policy_arn = aws_iam_policy.matomo_web_secrets.arn
}

resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "every-hour"
  schedule_expression = "rate(1 hour)"
}

data "template_file" "matomo_config_file_part_one" {
  template = file("${path.module}/files/matomo/matomo-config-file-part-one.ini.php")

  vars = {
    db_host      = aws_db_instance.matomo.address
    db_password  = random_string.matomo_db_password.result
    trusted_host = aws_route53_record.matomo.name
    salt         = var.matomo_salt
  }
}

resource "aws_ssm_parameter" "matomo_config_file_part_one" {
  name        = "/matomo/config-file-part-one"
  description = "Base64 encoded config file part one for Matomo"
  type        = "SecureString"
  key_id      = aws_kms_key.matomo.arn
  value       = base64encode(data.template_file.matomo_config_file_part_one.rendered)
}

resource "aws_ssm_parameter" "matomo_config_file_part_two" {
  name        = "/matomo/config-file-part-two"
  description = "Base64 encoded config file part two for Matomo"
  type        = "SecureString"
  key_id      = aws_kms_key.matomo.arn
  value       = base64encode(file("${path.module}/files/matomo/matomo-config-file-part-two.ini.php"))
}

resource "random_string" "matomo_db_password" {
  length  = 41
  special = false
}

resource "aws_ssm_parameter" "matomo_db_password" {
  name   = "/matomo/mysql-password"
  type   = "SecureString"
  key_id = aws_kms_key.matomo.arn
  value  = random_string.matomo_db_password.result
}

resource "aws_db_subnet_group" "matomo_db" {
  name       = "matomo-db"
  subnet_ids = aws_subnet.internal.*.id
}

locals {
  engine         = "mysql"
  engine_version = "5.7"
}

resource "aws_db_parameter_group" "matomo" {
  name   = "matamo-rds"
  family = "${local.engine}${local.engine_version}"

  parameter {
    name  = "max_allowed_packet"
    value = "67108864"
  }
}

resource "aws_db_instance" "matomo" {
  allocated_storage         = 500
  engine                    = local.engine
  engine_version            = local.engine_version
  storage_type              = "gp2"
  identifier                = "matomo"
  name                      = "matomo"
  username                  = "matomo"
  password                  = random_string.matomo_db_password.result
  vpc_security_group_ids    = [aws_security_group.matomo_db.id]
  db_subnet_group_name      = aws_db_subnet_group.matomo_db.name
  final_snapshot_identifier = "matomo-final"
  backup_retention_period   = 7
  storage_encrypted         = true
  parameter_group_name      = aws_db_parameter_group.matomo.name
  deletion_protection       = true

  ca_cert_identifier = "rds-ca-2019"

  # 8x vCPU, 25.5x ECU, 32GiB RAM
  # more here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
  instance_class = var.matomo_db_instance_class
}

resource "aws_security_group" "matomo_db" {
  name        = "matomo-db"
  description = "matomo-db"
  vpc_id      = aws_vpc.hub.id
}

resource "aws_security_group_rule" "matomo_db_allows_ingress_from_matomo" {
  type      = "ingress"
  from_port = "3306"
  to_port   = "3306"
  protocol  = "tcp"

  security_group_id        = aws_security_group.matomo_db.id
  source_security_group_id = aws_security_group.matomo.id
}
