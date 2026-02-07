# ================================
# VPC Outputs
# ================================
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr
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

output "nat_gateway_ids" {
  value       = module.vpc.nat_gateway_ids
  description = "NAT Gateway IDs"
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
output "frontend_ecs_cluster_name" {
  value       = module.ecs_frontend.cluster_name
  description = "Name of the frontend ECS cluster"
}

output "frontend_ecs_cluster_id" {
  value       = module.ecs_frontend.cluster_id
  description = "ID of the frontend ECS cluster"
}

output "frontend_ecs_service_name" {
  value       = module.ecs_frontend.service_name
  description = "Name of the frontend ECS service"
}

output "frontend_cloudwatch_log_group" {
  value       = module.ecs_frontend.log_group_name
  description = "Name of the frontend CloudWatch log group"
}

output "backend_ecs_cluster_name" {
  value       = module.ecs_backend.cluster_name
  description = "Name of the backend ECS cluster"
}

output "backend_ecs_cluster_id" {
  value       = module.ecs_backend.cluster_id
  description = "ID of the backend ECS cluster"
}

output "backend_ecs_service_name" {
  value       = module.ecs_backend.service_name
  description = "Name of the backend ECS service"
}

output "backend_cloudwatch_log_group" {
  value       = module.ecs_backend.log_group_name
  description = "Name of the backend CloudWatch log group"
}

# ================================
# RDS Outputs
# ================================
output "rds_cluster_endpoint" {
  value       = module.rds.cluster_endpoint
  description = "RDS cluster endpoint"
}

output "rds_reader_endpoint" {
  value       = module.rds.cluster_reader_endpoint
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

output "frontend_ecs_security_group_id" {
  value       = aws_security_group.frontend.id
  description = "Frontend ECS security group ID"
}

output "backend_ecs_security_group_id" {
  value       = aws_security_group.backend.id
  description = "Backend ECS security group ID"
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "RDS security group ID"
}
