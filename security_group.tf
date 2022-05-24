resource "aws_security_group" "this" {
  name        = var.container_name
  description = "Allow ${var.container_name} website traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description      = "80 from internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # egress is required in order to connect to the ECR
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = var.container_name
  }
}
