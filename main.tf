terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_iam_role" "task_role" {
  name = "${var.container_name}_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "allow_s3"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:*",
          ]
          Effect   = "Allow"
          Resource = "${aws_s3_bucket.this.arn}/*"
        },
        {
          Action = [
            "s3:ListAllMyBuckets",
            "s3:GetBucketLocation",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}
resource "aws_ecs_task_definition" "this" {
  family                   = var.container_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "wordpress:php8.0-apache"
      essential = true
      environment = [
        { name = "WORDPRESS_DB_HOST", value = aws_db_instance.this.endpoint },
        { name = "WORDPRESS_DB_NAME", value = var.container_name },
        { name = "WORDPRESS_DB_USER", value = local.db_cred.username },
        { name = "WORDPRESS_DB_PASSWORD", value = local.db_cred.password },
        { name = "WP_DEBUG", value = "true" },
      ]
      portMappings = [
        {
          containerPort = 80
        },
      ]
      mountPoints = [
        {
          sourceVolume  = "wordpress-efs",
          containerPath = "/var/www/html/"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "ecs"
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "ecs",
        }
      }
    }
  ])
  volume {
    name = "wordpress-efs"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = "DISABLED"
    }
  }
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_cluster" "this" {
  name               = var.container_name
  capacity_providers = ["FARGATE"]
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = var.container_name
      }
    }
  }
}
resource "aws_ecs_service" "this" {
  name                 = var.container_name
  cluster              = aws_ecs_cluster.this.id
  task_definition      = aws_ecs_task_definition.this.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  force_new_deployment = true
  network_configuration {
    subnets          = [aws_subnet.this_1.id, aws_subnet.this_2.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.this.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.container_name
    container_port   = 80
  }
}
resource "aws_cloudwatch_log_group" "this" {
  name              = "ecs"
  retention_in_days = 1
}
