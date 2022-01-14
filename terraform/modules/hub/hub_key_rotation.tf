resource "aws_s3_bucket" "hkr_sam" {
  bucket = "govukverify-hkr-${var.deployment}"
  region = data.aws_region.region.id
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = var.deployment
    ManagedStackSource = "AwsSamCli"
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "hkr_sam_bucket_policy" {
  statement {
    sid    = "HKRSamBucketPolicy"
    effect = "Allow"

    principals {
      type="AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/accounts-deployer-role"
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.hkr_sam.arn}", 
      "${aws_s3_bucket.hkr_sam.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "hkr_sam_policy" {
  bucket = aws_s3_bucket.hkr_sam.id
  policy = data.aws_iam_policy_document.hkr_sam_bucket_policy.json
}

resource "aws_ecr_repository" "hub_key_rotation" {
  name = "verify-hub-key-rotation"
}

resource "aws_ecr_repository_policy" "hub_key_rotation_policy" {
  repository = aws_ecr_repository.hub_key_rotation.name

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPushPullForDeployerRole",
            "Effect": "Allow",
            "Principal": {
              "AWS": ["arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/accounts-deployer-role"],
              "Service": "lambda.amazonaws.com"
            },
            "Action": [
              "ecr:BatchGetImage",
              "ecr:BatchCheckLayerAvailability",
              "ecr:CompleteLayerUpload",
              "ecr:GetDownloadUrlForLayer",
              "ecr:InitiateLayerUpload",
              "ecr:PutImage",
              "ecr:UploadLayerPart"
            ]
        }
    ]
  }
EOF
}

resource "aws_ecr_lifecycle_policy" "hkr_lifecycle_policy" {
  repository = aws_ecr_repository.hub_key_rotation.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Expire images older than 200 days",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": 999
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
EOF
}

resource "aws_security_group" "sg_hkr_lambda_prom_internal" {
  name        = "${var.deployment}-mgmt-internal-lb"
  description = "${var.deployment}-mgmt-internal-lb"

  vpc_id = aws_vpc.hub.id
}

resource "aws_security_group" "sg_hkr_lambda" {
  name        = "${var.deployment}-hkr-lambda"
  description = "${var.deployment}-hkr-lambda"

  vpc_id = aws_vpc.hub.id
}

resource "aws_security_group_rule" "sg_hkr_lambda_egress" {
  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
  cidr_blocks = [aws_vpc.hub.cidr_block]
  security_group_id = aws_security_group.sg_hkr_lambda.id
}

module "lambda_prom_lb_can_talk_to_prometheus" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.sg_hkr_lambda_prom_internal.id
  destination_sg_id = aws_security_group.prometheus.id

  port = 9090
}

resource "aws_security_group_rule" "sg_prom_internal_lb_rule" {
  type      = "ingress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"

  source_security_group_id = aws_security_group.sg_hkr_lambda.id
  security_group_id        = aws_security_group.sg_hkr_lambda_prom_internal.id
}
resource "aws_lb" "hkr_lambda_prom_internal_lb" {
  name               = "${var.deployment}-mgmt-internal"
  internal           = true
  load_balancer_type = "application"

  security_groups = [aws_security_group.sg_hkr_lambda_prom_internal.id]
  subnets         = aws_subnet.internal.*.id

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_lb_listener" "lambda_prom_internal_http" {
  load_balancer_arn = aws_lb.hkr_lambda_prom_internal_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_internal.arn
  }
}

resource "aws_lb_target_group" "prometheus_internal" {

  name     = "${var.deployment}-prometheus-internal"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = aws_vpc.hub.id

  health_check {
    path     = "/metrics"
    protocol = "HTTP"
    interval = 10
    timeout  = 5
  }
}

resource "aws_lb_target_group_attachment" "prometheus_internal" {
  count = var.number_of_prometheus_apps

  target_group_arn = aws_lb_target_group.prometheus_internal.arn
  target_id        = element(aws_instance.prometheus.*.id, count.index)
  port             = 9090
}

resource "aws_lb_listener_rule" "prometheus_http" {
  count        = var.number_of_prometheus_apps
  listener_arn = aws_lb_listener.lambda_prom_internal_http.arn
  priority     = 100 + count.index

  action {
    type = "forward"

    target_group_arn = aws_lb_target_group.prometheus_internal.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}
