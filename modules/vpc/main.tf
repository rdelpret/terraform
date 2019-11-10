
# --- VPC Network


resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.vpc_name}-${var.environment}"
    environment = "${var.environment}"
  }
}


# --- Private Subnets


resource "aws_subnet" "private" {
  count = "${length(var.private_subnets)}"

  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${element(var.private_subnets, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${format("%s-private-subnet-%s-%d", var.vpc_name, var.environment, count.index + 1)}"
    environment = "${var.environment}"
  }
}


# --- Public Subnets


resource "aws_subnet" "public" {
  count = "${length(var.public_subnets)}"

  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${element(var.public_subnets, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${format("%s-public-subnet-%s-%d", var.vpc_name, var.environment, count.index + 1)}"
    environment = "${var.environment}"
  }
}


# --- Private NAT gateway

resource "aws_eip" "nat_eip" {
  count = "${length(var.private_subnets)}"
  vpc   = true
}

resource "aws_nat_gateway" "private" {
  count = "${length(var.private_subnets)}"

  allocation_id = "${element(aws_eip.nat_eip.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  tags = {
    Name        = "${var.vpc_name}-nat-gateway-${var.environment}"
    environment = "${var.environment}"
  }
}

# --- Private Routing

resource "aws_route_table" "private" {
  count  = "${length(var.private_subnets)}"
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.private.*.id, count.index)}"
  }

  tags = {
    Name        = "${var.vpc_name}-private-route-table-${var.environment}"
    environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets)}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}


# --- Internet Gateway

resource "aws_internet_gateway" "igw" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.vpc_name}-intenet-gateway-${var.environment}"
    environment = "${var.environment}"
  }
}


# --- Public Routing

resource "aws_route_table" "public" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${element(aws_internet_gateway.igw.*.id, 0)}"
  }

  tags = {
    Name        = "${var.vpc_name}-public-route-table-${var.environment}"
    environment = "${var.environment}"
  }
}


resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnets)}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, 0)}"
}
