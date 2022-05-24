resource "aws_efs_file_system" "this" {
  tags = {
    Name = "${var.container_name} EFS"
  }
}
resource "aws_efs_mount_target" "this1" {
  file_system_id = aws_efs_file_system.this.id
  subnet_id      = aws_subnet.this_1.id
  security_groups = [aws_security_group.efs.id]
}
resource "aws_efs_mount_target" "this2" {
  file_system_id = aws_efs_file_system.this.id
  subnet_id      = aws_subnet.this_2.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name        = "${var.container_name}-efs"
  description = "Allow ${var.container_name} to connect to EFS"
  vpc_id = aws_vpc.this.id

  ingress {
    description      = "EFS"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    security_groups = [aws_security_group.this.id]
  }
  tags = {
    Name = "${var.container_name} EFS"
  }
}
