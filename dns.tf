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
