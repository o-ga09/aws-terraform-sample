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
  default     = "development"
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
variable "container_port" {
  type        = number
  description = "Port exposed by the container"
  default     = 80
}

variable "container_image" {
  type        = string
  description = "Full container image URI (e.g., 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:latest). If specified, container_image_registry, container_image_repository, and container_image_tag are ignored"
  default     = ""
}

variable "container_image_registry" {
  type        = string
  description = "Container image registry (e.g., 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com)"
  default     = ""
}

variable "container_image_repository" {
  type        = string
  description = "Container image repository name (e.g., myapp)"
  default     = ""
}

variable "container_image_tag" {
  type        = string
  description = "Container image tag. Supports dynamic tags like 'development:abc123def456' or 'v1.0.0'"
  default     = "latest"
}

variable "use_ecr_url" {
  type        = bool
  description = "When true, automatically use ECR repository URL and name for container_image_registry and container_image_repository (if not manually specified)"
  default     = true
}

variable "container_name" {
  type        = string
  description = "Name of the container"
  default     = "app"
}

variable "replica_count" {
  type        = number
  description = "Number of task replicas"
  default     = 2
}

variable "task_cpu" {
  type        = number
  description = "CPU units for the task"
  default     = 512
}

variable "task_memory" {
  type        = number
  description = "Memory in MB for the task"
  default     = 1024
}

variable "container_environment" {
  type        = map(string)
  description = "Environment variables for container"
  default     = {}
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Enable auto-scaling for ECS service"
  default     = true
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of tasks for auto-scaling"
  default     = 4
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks for auto-scaling"
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
  description = "The name of the parameter in Parameter Store containing the master password (e.g., /database/development/password)"
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

variable "min_capacity" {
  type        = number
  description = "Minimum capacity for Aurora Serverless"
  default     = 0.5
}

variable "max_capacity" {
  type        = number
  description = "Maximum capacity for Aurora Serverless"
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
