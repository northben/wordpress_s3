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
resource "aws_lb" "this" {
  name               = "${var.container_name}-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = [aws_subnet.this_1.id, aws_subnet.this_2.id]
}
resource "aws_lb_target_group" "this" {
  name        = var.container_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"
#   health_check {
#     path = "/en-US/account/login"
#   }
}
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_route53_record" "s3demo" {
  zone_id = var.route53_zone
  name    = var.dns_name
  type    = "A"
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}
