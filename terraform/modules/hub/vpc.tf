resource "aws_vpc" "hub" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.hub.id}"
  service_name = "com.amazonaws.eu-west-2.s3"

  route_table_ids = "${aws_route_table.private.*.id}"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:PutObjectAcl",
                "s3:PutObject",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:Delete*"
            ],
            "Resource": [
                "arn:aws:s3:::prod-eu-west-2-starport-layer-bucket",
                "arn:aws:s3:::prod-eu-west-2-starport-layer-bucket/*",
                "arn:aws:s3:::gds-${var.deployment}-ssm-session-logs-store",
                "arn:aws:s3:::gds-${var.deployment}-ssm-session-logs-store/*",
                "arn:aws:s3:::govukverify-self-service-${var.deployment}-config-metadata",
                "arn:aws:s3:::govukverify-self-service-${var.deployment}-config-metadata/*",
                "arn:aws:s3:::govukverify-self-service-integration-config-metadata",
                "arn:aws:s3:::govukverify-self-service-integration-config-metadata/*"
            ]
        }
    ]
  }
  EOF
}

resource "aws_security_group" "cloudwatch_vpc_endpoint" {
  name        = "${var.deployment}-cloudwatch-vpc-endpoint"
  description = "${var.deployment}-cloudwatch-vpc-endpoint"

  vpc_id = "${aws_vpc.hub.id}"
}

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.monitoring"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.cloudwatch_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_security_group" "container_vpc_endpoint" {
  name        = "${var.deployment}-container-vpc-endpoint"
  description = "${var.deployment}-container-vpc-endpoint"

  vpc_id = "${aws_vpc.hub.id}"
}

resource "aws_security_group" "can_connect_to_container_vpc_endpoint" {
  name        = "${var.deployment}-can-connect-to-container-vpc-endpoint"
  description = "${var.deployment}-can-connect-to-container-vpc-endpoint"

  vpc_id = "${aws_vpc.hub.id}"
}

module "container_vpc_endpoint_sg_connection" {
  source = "./modules/microservice_connection"

  source_sg_id      = "${aws_security_group.can_connect_to_container_vpc_endpoint.id}"
  destination_sg_id = "${aws_security_group.container_vpc_endpoint.id}"
}

resource "aws_security_group_rule" "container_vpc_endpoint_sg_s3_endpoint" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = "${aws_security_group.can_connect_to_container_vpc_endpoint.id}"
  prefix_list_ids   = ["${aws_vpc_endpoint.s3.prefix_list_id}"]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecs_agent" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ecs-agent"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecs_telemetry" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ecs-telemetry"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecs" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ecs"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ssmmessages"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ec2"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id            = "${aws_vpc.hub.id}"
  service_name      = "com.amazonaws.eu-west-2.ec2messages"
  vpc_endpoint_type = "Interface"

  subnet_ids = "${aws_subnet.internal.*.id}"

  security_group_ids = ["${aws_security_group.container_vpc_endpoint.id}"]

  private_dns_enabled = true
}
