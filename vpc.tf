resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.container_name} Internet gateway"
  }
}
resource "aws_vpc" "this" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.container_name} VPC"
  }
}
resource "aws_subnet" "this_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "172.31.48.0/20"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.container_name} 1"
  }
}
resource "aws_subnet" "this_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "172.31.64.0/20"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "${var.container_name} 2"
  }
}
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
  tags = {
    Name = "${var.container_name} route table"
  }
}
resource "aws_route_table_association" "rta_subnet1" {
  subnet_id      = aws_subnet.this_1.id
  route_table_id = aws_route_table.this.id
}
resource "aws_route_table_association" "rta_subnet2" {
  subnet_id      = aws_subnet.this_2.id
  route_table_id = aws_route_table.this.id
}
