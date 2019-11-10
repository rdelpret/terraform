variable "environment" {
  default = {
    staging = "staging"
    prod    = "prod"
  }
}

variable "network_segment" {
  default     = "vpn-to-vpc"
  description = "vpn-to-vpc"
}

variable "cidr_block" {
  default = "172.16.0.0/22"
  type    = "string"
}

variable "availability_zones" {
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
  type    = "list"
}
