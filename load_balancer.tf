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
