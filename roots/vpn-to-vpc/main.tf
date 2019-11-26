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

resource "aws_security_group" "port2277" {
  name        = "${var.environment[terraform.workspace]}-elb-sg"
  description = "Allow port 2277 to elb"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 2277
    to_port     = 2277
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_elb" "load_balancer" {
  name            = "${var.environment[terraform.workspace]}-elb"
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.port2277.id]
  //access_logs {
  //  bucket        = "foo"
  //  bucket_prefix = "bar"
  //  interval      = 60
  //}

  listener {
    instance_port     = 22
    instance_protocol = "TCP"
    lb_port           = 2277
    lb_protocol       = "TCP"
  }
  tags = {
    Name        = "elb-${var.environment[terraform.workspace]}"
    environment = "${var.environment[terraform.workspace]}"
  }
}
