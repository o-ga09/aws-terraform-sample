# ================================
# VPC Outputs
# ================================
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs"
}

output "nat_gateway_ips" {
  value       = module.vpc.nat_gateway_public_ips
  description = "NAT Gateway public IPs"
}

# ================================
# ALB Outputs
# ================================
output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "DNS name of the load balancer"
}

output "alb_arn" {
  value       = module.alb.alb_arn
  description = "ARN of the load balancer"
}

output "alb_zone_id" {
  value       = module.alb.alb_zone_id
  description = "Zone ID of the load balancer"
}

output "target_group_arn" {
  value       = module.alb.target_group_arn
  description = "ARN of the target group"
}

# ================================
# ECR Outputs
# ================================
output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL"
}

output "ecr_repository_arn" {
  value       = module.ecr.repository_arn
  description = "ECR repository ARN"
}

# ================================
# ECS Outputs
# ================================
output "ecs_cluster_name" {
  value       = module.ecs.cluster_name
  description = "Name of the ECS cluster"
}

output "ecs_cluster_arn" {
  value       = module.ecs.cluster_arn
  description = "ARN of the ECS cluster"
}

output "ecs_service_name" {
  value       = module.ecs.service_name
  description = "Name of the ECS service"
}

output "cloudwatch_log_group" {
  value       = module.ecs.cloudwatch_log_group_name
  description = "Name of the CloudWatch log group"
}

# ================================
# RDS Outputs
# ================================
output "rds_cluster_endpoint" {
  value       = module.rds.cluster_endpoint
  description = "RDS cluster endpoint"
}

output "rds_reader_endpoint" {
  value       = module.rds.reader_endpoint
  description = "RDS reader endpoint"
}

output "rds_cluster_arn" {
  value       = module.rds.cluster_arn
  description = "RDS cluster ARN"
}

output "rds_database_name" {
  value       = module.rds.database_name
  description = "Initial database name"
}

# ================================
# Security Group Outputs
# ================================
output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALB security group ID"
}

output "ecs_security_group_id" {
  value       = aws_security_group.ecs.id
  description = "ECS security group ID"
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "RDS security group ID"
}
