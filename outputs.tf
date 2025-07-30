output "aws_vpc" {
  value = aws_vpc.main.id
}

output "dns_ALB" {
  value = aws_lb.main_alb.dns_name
}