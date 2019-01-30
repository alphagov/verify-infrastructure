data "aws_availability_zones" "available" {}

locals {
  azs = "${
    slice(
      data.aws_availability_zones.available.names,
      0,
      local.number_of_availability_zones
    )
  }"
}
