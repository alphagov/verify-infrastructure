resource "aws_vpc" "hub" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.hub.id}"
  service_name = "com.amazonaws.eu-west-2.s3"

  route_table_ids = [
    "${aws_route_table.private.*.id}"
  ]

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
                "arn:aws:s3:::govukverify-eidas-metadata-aggregator-${var.deployment}-a/*",
                "arn:aws:s3:::govukverify-eidas-metadata-aggregator-${var.deployment}-a"
            ]
        }
    ]
  }
  EOF
}
