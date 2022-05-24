resource "aws_db_instance" "this" {
  allocated_storage    = 5
  engine               = "mariadb"
  engine_version       = "10.6.5"
  instance_class       = "db.t4g.small"
  name                 = var.container_name
  username             = local.db_cred.username
  password             = local.db_cred.password
  skip_final_snapshot  = true
  apply_immediately    = true
  db_subnet_group_name = aws_db_subnet_group.this.name
  storage_type         = "standard"
  vpc_security_group_ids = [
    aws_security_group.database.id,
  ]
}

resource "random_password" "password" {
  length           = 16
  override_special = "`~!#$%^&*()-_+=[]{};:,.<>?"
}

resource "aws_secretsmanager_secret" "this" {
  name = "${var.container_name}-RDS-credential"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = "db_user"
    password = "${random_password.password.result}"
  })
}

data "aws_secretsmanager_secret" "this" {
  arn = aws_secretsmanager_secret.this.arn
}
data "aws_secretsmanager_secret_version" "this" {
  secret_id = data.aws_secretsmanager_secret.this.arn
}
locals {
  db_cred = jsondecode(data.aws_secretsmanager_secret_version.this.secret_string)
}
resource "aws_db_subnet_group" "this" {
  name       = "${var.container_name}-db"
  subnet_ids = [aws_subnet.db_1.id, aws_subnet.db_2.id]

  tags = {
    Name = "${var.container_name} DB subnet group"
  }
}

resource "aws_subnet" "db_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "172.31.80.0/20"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.container_name} DB 1"
  }
}
resource "aws_subnet" "db_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "172.31.96.0/20"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "${var.container_name} DB 2"
  }
}

resource "aws_security_group" "database" {
  name        = "${var.container_name} db subnet"
  description = "${var.container_name} database traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "mariadb"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.this.id]
  }

  tags = {
    Name = "${var.container_name} DB"
  }
}
