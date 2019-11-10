variable "environment" {}

variable "availability_zones" {
  description = "List of availability zones across which to distribute subnets"
  type        = "list"
}

variable "cidr_block" {
  description = "The VPC address space in CIDR notation"
  type        = "string"
}

variable "private_subnets" {
  description = "List of private subnet address spaces in CIDR notation"
  type        = "list"
}

variable "public_subnets" {
  description = "List of public subnet address spaces in CIDR notation"
  type        = "list"
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = "string"
}
