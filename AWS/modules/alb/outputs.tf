output "alb_arn" {
  value       = aws_lb.main.arn
  description = "ARN of the Application Load Balancer"
}

output "alb_id" {
  value       = aws_lb.main.id
  description = "ID of the Application Load Balancer"
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "alb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "Zone ID of the Application Load Balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.main.arn
  description = "ARN of the target group"
}

output "target_group_id" {
  value       = aws_lb_target_group.main.id
  description = "ID of the target group"
}

output "target_group_name" {
  value       = aws_lb_target_group.main.name
  description = "Name of the target group"
}

output "http_listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "ARN of the HTTP listener"
}

output "https_listener_arn" {
  value       = try(aws_lb_listener.https[0].arn, "")
  description = "ARN of the HTTPS listener (if enabled)"
}
