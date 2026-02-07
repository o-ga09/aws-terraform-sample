# ================================
# General Variables
# ================================
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-northeast-1"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

# ================================
# VPC Variables
# ================================
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for subnets"
}

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for database subnets"
}

variable "management_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for management subnets"
}

# ================================
# ALB Variables
# ================================
variable "enable_https" {
  type        = bool
  description = "Enable HTTPS listener"
  default     = true
}

variable "certificate_arn" {
  type        = string
  description = "ARN of SSL/TLS certificate for HTTPS listener"
  default     = ""
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for ALB"
  default     = true
}

variable "enable_access_logs" {
  type        = bool
  description = "Enable access logs for ALB"
  default     = true
}

variable "access_logs_s3_bucket" {
  type        = string
  description = "S3 bucket for ALB access logs"
  default     = ""
}

# ================================
# Common ECS Variables
# ================================
variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

# ================================
# ECR Variables
# ================================
variable "repository_name" {
  type        = string
  description = "Name of the ECR repository"
}

variable "image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the repository"
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Scan image on push to the repository"
  default     = true
}

variable "enable_lifecycle_policy" {
  type        = bool
  description = "Enable lifecycle policy for image retention"
  default     = true
}

variable "image_retention_count" {
  type        = number
  description = "Number of images to retain in the repository"
  default     = 10
}

variable "encryption_type" {
  type        = string
  description = "The encryption type to use for the repository"
  default     = "AES256"
}

variable "kms_key_id" {
  type        = string
  description = "ARN of the KMS key"
  default     = null
}

# ================================
# ECS Variables
# ================================
# Frontend ECS Service Configuration
variable "frontend_container_port" {
  type        = number
  description = "Port exposed by the frontend container"
  default     = 3000
}

variable "frontend_container_name" {
  type        = string
  description = "Name of the frontend container"
  default     = "frontend"
}

variable "frontend_container_image" {
  type        = string
  description = "Full container image URI for frontend"
  default     = ""
}

variable "frontend_container_image_tag" {
  type        = string
  description = "Container image tag for frontend"
  default     = "latest"
}

variable "frontend_use_ecr_url" {
  type        = bool
  description = "When true, automatically use ECR repository URL for frontend container image"
  default     = true
}

variable "frontend_replica_count" {
  type        = number
  description = "Number of frontend task replicas"
  default     = 2
}

variable "frontend_task_cpu" {
  type        = number
  description = "CPU units for the frontend task"
  default     = 512
}

variable "frontend_task_memory" {
  type        = number
  description = "Memory in MB for the frontend task"
  default     = 1024
}

variable "frontend_container_environment" {
  type        = map(string)
  description = "Environment variables for frontend container"
  default     = {}
}

variable "frontend_enable_auto_scaling" {
  type        = bool
  description = "Enable auto-scaling for frontend ECS service"
  default     = true
}

variable "frontend_ecs_task_max_capacity" {
  type        = number
  description = "Maximum number of frontend tasks for auto-scaling"
  default     = 4
}

variable "frontend_ecs_task_min_capacity" {
  type        = number
  description = "Minimum number of frontend tasks for auto-scaling"
  default     = 2
}

# Backend ECS Service Configuration
variable "backend_container_port" {
  type        = number
  description = "Port exposed by the backend container"
  default     = 8080
}

variable "backend_container_name" {
  type        = string
  description = "Name of the backend container"
  default     = "backend"
}

variable "backend_container_image" {
  type        = string
  description = "Full container image URI for backend"
  default     = ""
}

variable "backend_container_image_tag" {
  type        = string
  description = "Container image tag for backend"
  default     = "latest"
}

variable "backend_replica_count" {
  type        = number
  description = "Number of backend task replicas"
  default     = 2
}

variable "backend_task_cpu" {
  type        = number
  description = "CPU units for the backend task"
  default     = 512
}

variable "backend_task_memory" {
  type        = number
  description = "Memory in MB for the backend task"
  default     = 1024
}

variable "backend_container_environment" {
  type        = map(string)
  description = "Environment variables for backend container"
  default     = {}
}

variable "backend_enable_auto_scaling" {
  type        = bool
  description = "Enable auto-scaling for backend ECS service"
  default     = true
}

variable "backend_ecs_task_max_capacity" {
  type        = number
  description = "Maximum number of backend tasks for auto-scaling"
  default     = 4
}

variable "backend_ecs_task_min_capacity" {
  type        = number
  description = "Minimum number of backend tasks for auto-scaling"
  default     = 2
}

# ================================
# RDS Variables
# ================================
variable "database_name" {
  type        = string
  description = "Initial database name"
}

variable "master_username" {
  type        = string
  description = "Master username for database"
  sensitive   = true
}

variable "master_password" {
  type        = string
  description = "Master password for database. Used only if use_secrets_manager and use_parameter_store are false"
  sensitive   = true
  default     = null
}

variable "use_parameter_store" {
  type        = bool
  description = "Whether to retrieve the master password from AWS Systems Manager Parameter Store"
  default     = false
}

variable "parameter_store_password_name" {
  type        = string
  description = "The name of the parameter in Parameter Store containing the master password (e.g., /database/production/password)"
  default     = null
}

variable "use_secrets_manager" {
  type        = bool
  description = "Whether to retrieve the master password from AWS Secrets Manager"
  default     = false
}

variable "secrets_manager_secret_name" {
  type        = string
  description = "The name of the secret in Secrets Manager containing the database password in JSON format with 'password' key"
  default     = null
}

variable "engine_version" {
  type        = string
  description = "Aurora MySQL version"
  default     = "8.0.mysql_aurora.3.02.0"
}

variable "is_serverless" {
  type        = bool
  description = "Use Aurora Serverless v2"
  default     = false
}

variable "instance_class" {
  type        = string
  description = "Instance class for Aurora"
  default     = "db.t4g.small"
}

variable "cluster_size" {
  type        = number
  description = "Number of instances in the cluster"
  default     = 2
}

variable "rds_min_capacity" {
  type        = number
  description = "Minimum capacity for Aurora Serverless (must be >= 1.0 for Serverless v2)"
  default     = 1
}

variable "rds_max_capacity" {
  type        = number
  description = "Maximum capacity for Aurora Serverless "
  default     = 2
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention period in days"
  default     = 30
}

variable "preferred_backup_window" {
  type        = string
  description = "Preferred backup window (HH:MM-HH:MM)"
  default     = "03:00-04:00"
}
