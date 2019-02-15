data "aws_caller_identity" "account" {}

data "aws_instances" "instances" {
  instance_tags = {
    Deployment = "${var.deployment}"
  }
}

data "aws_instance" "instance" {
  count       = "${length(data.aws_instances.instances.ids)}"
  instance_id = "${data.aws_instances.instances.ids[count.index]}"
}

data "aws_iam_instance_profile" "instance_profile" {
  count = "${data.aws_instance.instance.count}"
  name  = "${data.aws_instance.instance.*.iam_instance_profile[count.index]}"
}

data "aws_iam_role" "instance_role" {
  count = "${data.aws_iam_instance_profile.instance_profile.count}"
  name  = "${data.aws_iam_instance_profile.instance_profile.*.role_name[count.index]}"
}
