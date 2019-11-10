provider "aws" {
  region = "us-east-2"
}

module "vpc" {
  source = "../../modules/vpc"

  availability_zones = "${var.availability_zones}"
  cidr_block         = "${var.cidr_block}"
  environment        = "${var.environment[terraform.workspace]}"
  vpc_name           = "${var.network_segment}"

  private_subnets = [
    "${cidrsubnet(var.cidr_block, 6, 3)}",
    "${cidrsubnet(var.cidr_block, 6, 4)}",
    "${cidrsubnet(var.cidr_block, 6, 5)}",
  ]

  public_subnets = [
    "${cidrsubnet(var.cidr_block, 6, 0)}",
    "${cidrsubnet(var.cidr_block, 6, 1)}",
    "${cidrsubnet(var.cidr_block, 6, 2)}",
  ]
}
