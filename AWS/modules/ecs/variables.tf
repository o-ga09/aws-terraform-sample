variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (development, staging, production)"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the container"
  default     = 80
}

variable "container_image" {
  type        = string
  description = "Full container image URI (ECR or Docker Hub). Can be overridden by container_image_registry, container_image_repository, and container_image_tag"
  default     = ""
}

variable "container_image_registry" {
  type        = string
  description = "Container image registry (e.g., 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com or docker.io)"
  default     = ""
}

variable "container_image_repository" {
  type        = string
  description = "Container image repository name"
  default     = ""
}

variable "container_image_tag" {
  type        = string
  description = "Container image tag (e.g., latest, v1.0.0, production:abc123def456)"
  default     = "latest"
}

variable "container_name" {
  type        = string
  description = "Name of the container"
  default     = "app"
}

variable "replica_count" {
  type        = number
  description = "Number of task replicas"
  default     = 1
}

variable "task_cpu" {
  type        = number
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Memory in MB for the task"
  default     = 512
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where ECS will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ECS task placement"
}

variable "ecs_security_group_id" {
  type        = string
  description = "Security group ID for ECS tasks"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the ALB target group (optional, leave empty if not using ALB)"
  default     = ""
}

variable "container_environment" {
  type        = map(string)
  description = "Environment variables for container"
  default     = {}
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 7
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Enable auto-scaling for ECS service"
  default     = false
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks for auto-scaling"
  default     = 1
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of tasks for auto-scaling"
  default     = 3
}

variable "target_cpu_utilization" {
  type        = number
  description = "Target CPU utilization percentage for auto-scaling"
  default     = 70
}

variable "health_check_grace_period" {
  type        = number
  description = "Grace period for health checks (seconds)"
  default     = 60
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}
