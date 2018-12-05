data "aws_ami" "awslinux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  owners = ["amazon"]
}

