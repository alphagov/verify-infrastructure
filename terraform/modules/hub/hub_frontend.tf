# frontend
#
# needs to connect to:
#   - config
#   - saml proxy
#   - policy
#
# frontend applications are run on the ingress asg

resource "aws_security_group" "frontend_task" {
  name        = "${var.deployment}-frontend-task"
  description = "${var.deployment}-frontend-task"

  vpc_id = "${aws_vpc.hub.id}"
}

data "template_file" "frontend_task_def" {
  template = "${file("${path.module}/files/tasks/stub.json")}"

  vars {
    app = "frontend"
  }
}
