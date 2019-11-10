output "cidr_block" {
  value = "${aws_vpc.vpc.cidr_block}"
}

output "private_subnets" {
  value = ["${aws_subnet.private.*.id}"]
}

output "private_availability_zones" {
  value = ["${aws_subnet.private.*.availability_zone}"]
}

output "public_availability_zones" {
  value = ["${aws_subnet.public.*.availability_zone}"]
}

output "public_subnets" {
  value = ["${aws_subnet.public.*.id}"]
}

output "vpc_name" {
  value = "${var.vpc_name}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}
